#!/usr/bin/env bash
# Publish a new RuStore version for the current git tag via RuStore Public API:
#   auth (RSA-подпись) → черновик версии → загрузка AAB → отправка на модерацию.
#
# Docs: https://www.rustore.ru/help/work-with-rustore-api/api-upload-publication-app
#
# Required CI/CD variables:
#   RUSTORE_KEY_ID       id ключа API (RuStore Консоль → Компания/Разработчик →
#                        API RuStore → Создать ключ; роль Владелец/Администратор)
#   RUSTORE_KEY_BASE64   приватный ключ этого API (PKCS#8, RSA) в base64, одна строка.
#                        GitLab Type=File тоже поддерживается — значение = путь к файлу.
# Optional CI/CD variables:
#   RUSTORE_PACKAGE_NAME    Android applicationId (default: com.mobileway.ui_clone)
#   RUSTORE_PUBLISH_TYPE    INSTANTLY (default) | MANUAL | DELAYED
#                           DELAYED требует RUSTORE_PUBLISH_DATETIME (yyyy-MM-dd'T'HH:mm:ssXXX)
#   RUSTORE_PRIORITY_UPDATE приоритет обновления 0..5 (default 0)
#   RUSTORE_MODER_INFO      комментарий модератору, <=180 символов
#   RUSTORE_DELETE_DRAFT    true (default) — удалить существующий черновик перед созданием
#
# Requires: curl, openssl, base64 (GNU — shell-runner Ubuntu).

set -Eeuo pipefail

ROOT="${CI_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "${ROOT}"

API="https://public-api.rustore.ru"
PACKAGE="${RUSTORE_PACKAGE_NAME:-com.mobileway.ui_clone}"
PUBLISH_TYPE="${RUSTORE_PUBLISH_TYPE:-INSTANTLY}"
PRIORITY="${RUSTORE_PRIORITY_UPDATE:-0}"
DELETE_DRAFT="${RUSTORE_DELETE_DRAFT:-true}"
CHANGELOG_FILE="${CHANGELOG_FILE:-CHANGELOG.md}"
PREFIX="${ARTIFACT_PREFIX:-UIClone}"

die() { echo "ERROR: $*" >&2; exit 1; }
log() { echo "→ $*"; }

command -v curl >/dev/null 2>&1 || die "curl not found"
command -v openssl >/dev/null 2>&1 || die "openssl not found"
command -v base64 >/dev/null 2>&1 || die "base64 not found"

: "${RUSTORE_KEY_ID:?Set RUSTORE_KEY_ID (id ключа API в RuStore Консоли)}"
: "${RUSTORE_KEY_BASE64:?Set RUSTORE_KEY_BASE64 (приватный ключ API в base64)}"

case "${PUBLISH_TYPE}" in
  INSTANTLY|MANUAL) ;;
  DELAYED)
    : "${RUSTORE_PUBLISH_DATETIME:?Set RUSTORE_PUBLISH_DATETIME (ISO8601, yyyy-MM-ddTHH:mm:ssXXX) for DELAYED}"
    ;;
  *) die "RUSTORE_PUBLISH_TYPE must be INSTANTLY, MANUAL or DELAYED (got: ${PUBLISH_TYPE})" ;;
esac

# --- Релизные метаданные (build.env из prepare, тег из CI) --------------------

if [ -f build.env ]; then
  set -a
  # shellcheck disable=SC1091
  source build.env
  set +a
fi

TAG="${CI_COMMIT_TAG:-${APP_RELEASE_LABEL:-}}"
[ -n "${TAG}" ] || die "Set CI_COMMIT_TAG or run after prepare:flutter (build.env)"
VERSION="${TAG#v}"

# Точный артефакт сборки: dist/android/<Prefix>-android-<tag>.aab,
# иначе единственный *.aab в dist/android (fallback для ручных запусков).
AAB_PATH="dist/android/${PREFIX}-android-${TAG}.aab"
if [ ! -f "${AAB_PATH}" ]; then
  shopt -s nullglob
  aab_candidates=(dist/android/*.aab)
  shopt -u nullglob
  if [ "${#aab_candidates[@]}" -eq 1 ]; then
    AAB_PATH="${aab_candidates[0]}"
    echo "WARN: expected ${PREFIX}-android-${TAG}.aab, using ${AAB_PATH}" >&2
  else
    die "AAB not found: dist/android/${PREFIX}-android-${TAG}.aab (built artifact required)"
  fi
fi
log "RuStore ${PACKAGE} ← ${TAG} (${AAB_PATH}, $(du -h "${AAB_PATH}" | cut -f1))"

# --- Приватный ключ: base64 → PEM (PKCS#8) -----------------------------------

WORK="$(mktemp -d)"
HTTP_OUT="${WORK}/http.out"
cleanup() { rm -rf "${WORK}"; }
trap cleanup EXIT
KEY_PEM="${WORK}/key.pem"

key_src="${RUSTORE_KEY_BASE64}"
if [ -f "${key_src}" ]; then
  # GitLab CI/CD переменная типа File: значение — путь к загруженному файлу.
  key_src="$(cat "${key_src}")"
fi

write_pem_from_der() {
  local der="$1"
  openssl pkey -inform DER -in "${der}" -outform PEM -out "${KEY_PEM}" 2>/dev/null ||
    openssl pkcs8 -inform DER -topk8 -nocrypt -in "${der}" -outform PEM -out "${KEY_PEM}" 2>/dev/null ||
    openssl rsa -inform DER -in "${der}" -out "${KEY_PEM}" 2>/dev/null
}

decoded="${WORK}/key.raw"
if printf '%s' "${key_src}" | grep -q -- '-----BEGIN'; then
  printf '%s\n' "${key_src}" > "${KEY_PEM}"                 # PEM как есть (не в base64)
elif printf '%s' "${key_src}" | tr -d '\n\r \t' | base64 --decode > "${decoded}" 2>/dev/null &&
  [ -s "${decoded}" ]; then
  if grep -q -- '-----BEGIN' "${decoded}"; then
    cp "${decoded}" "${KEY_PEM}"                            # base64(PEM-текст)
  else
    write_pem_from_der "${decoded}" || die "RUSTORE_KEY_BASE64 decodes, but is not a valid PKCS#8/RSA key"
  fi
else
  die "RUSTORE_KEY_BASE64 is neither valid base64 nor PEM"
fi
chmod 600 "${KEY_PEM}"
openssl pkey -in "${KEY_PEM}" -noout </dev/null 2>/dev/null ||
  die "RUSTORE_KEY_BASE64 does not contain a parseable private key"

# --- Авторизация: POST /public/auth → JWE-токен (TTL 900 с) ------------------
# signature = base64(SHA512withRSA(keyId + timestamp)), ключ — PKCS#8.

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%S.000+00:00)"
SIGNATURE="$(
  printf '%s' "${RUSTORE_KEY_ID}${TIMESTAMP}" |
    openssl dgst -sha512 -sign "${KEY_PEM}" -binary | base64 | tr -d '\n'
)"
[ -n "${SIGNATURE}" ] || die "RSA signature generation failed"

TOKEN=""
API_CODE=""

# api_call METHOD URL [curl-args...] → API_CODE, тело в $HTTP_OUT.
api_call() {
  local method="$1" url="$2"
  shift 2
  local auth=()
  if [ -n "${TOKEN}" ]; then
    auth=(-H "Public-Token: ${TOKEN}")
  fi
  API_CODE="$(
    curl -sS --connect-timeout 15 --max-time 300 \
      -X "${method}" -o "${HTTP_OUT}" -w '%{http_code}' \
      "${auth[@]}" "$@" "${url}"
  )" || die "curl failed: ${method} ${url}"
}

print_rights_hint() {
  cat >&2 <<'EOF'
Hint: ключ API RuStore не имеет прав на этот метод.
  → RuStore Консоль → Компания/Разработчик → API RuStore → «Заменить ключ»
  → включить методы группы «Загрузка и публикация приложений»
    (создание черновика версии, загрузка AAB, отправка на модерацию)
  → выбрать приложение UI Clone (или «Все приложения»)
  → обновить RUSTORE_KEY_ID / RUSTORE_KEY_BASE64 в GitLab CI/CD Variables.
EOF
}

expect_ok() {
  local ctx="$1"
  if [ "${API_CODE:0:1}" != "2" ] ||
    ! grep -qE '"code"[[:space:]]*:[[:space:]]*"OK"' "${HTTP_OUT}"; then
    echo "RuStore API error (${ctx}): HTTP ${API_CODE}" >&2
    head -c 2000 "${HTTP_OUT}" >&2 || true
    echo >&2
    if [ "${API_CODE}" = "403" ] || grep -qi 'does not have rights' "${HTTP_OUT}"; then
      print_rights_hint
    fi
    exit 1
  fi
}

json_str() { # json-string field: name
  printf '%s' "$(cat "${HTTP_OUT}")" |
    sed -nE "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/p" | head -1
}

AUTH_PAYLOAD="$(printf '{"keyId":"%s","timestamp":"%s","signature":"%s"}' \
  "${RUSTORE_KEY_ID}" "${TIMESTAMP}" "${SIGNATURE}")"
api_call POST "${API}/public/auth" -H 'Content-Type: application/json' --data "${AUTH_PAYLOAD}"
TOKEN="$(json_str jwe)"
[ -n "${TOKEN}" ] || {
  echo "RuStore auth failed: HTTP ${API_CODE}" >&2
  head -c 2000 "${HTTP_OUT}" >&2 || true
  echo >&2
  if [ "${API_CODE}" = "403" ] || grep -qi 'does not have rights' "${HTTP_OUT}"; then
    print_rights_hint
  fi
  exit 1
}
log "Authorized (JWE token received)"

# --- Существующие версии: нужна активная версия, ждём модерацию, чистим черновик ---

# RuStore Public API не создаёт черновик, пока у приложения нет ни одной
# активной версии (первая публикация — только вручную через Консоль).
STATUS_URL="${API}/public/v1/application/${PACKAGE}/version?versionStatuses=ACTIVE,PARTIAL_ACTIVE,PREVIOUS_ACTIVE,DRAFT,TAKEN_FOR_MODERATION,MODERATION,AUTO_CHECK,READY_FOR_PUBLICATION,REJECTED_BY_MODERATOR&filterTestingType=ALL&page=0&size=100"
api_call GET "${STATUS_URL}"
expect_ok "list versions"

# Пары versionId/versionStatus из JSON (порядок полей в ответе сохраняется).
VERSION_ROWS="$(
  tr -d '\n\r' < "${HTTP_OUT}" |
    grep -oE '"versionId"[[:space:]]*:[[:space:]]*[0-9]+|"versionStatus"[[:space:]]*:[[:space:]]*"[A-Z_]+"' |
    paste - - |
    sed -E 's/.*"versionId"[[:space:]]*:[[:space:]]*([0-9]+).*"versionStatus"[[:space:]]*:[[:space:]]*"([A-Z_]+)".*/\1 \2/' |
    grep -E '^[0-9]+ ' || true
)"

HAS_ACTIVE=""
while read -r vid vstatus; do
  [ -n "${vid}" ] || continue
  case "${vstatus}" in
    ACTIVE|PARTIAL_ACTIVE) HAS_ACTIVE="true" ;;
    DRAFT)
      if [ "${DELETE_DRAFT}" = "true" ]; then
        log "Deleting existing draft versionId=${vid} (RuStore allows one draft per app)"
        api_call DELETE "${API}/public/v1/application/${PACKAGE}/version/${vid}"
        expect_ok "delete draft ${vid}"
      else
        die "Draft versionId=${vid} already exists (set RUSTORE_DELETE_DRAFT=true to replace it)"
      fi
      ;;
    TAKEN_FOR_MODERATION|MODERATION|AUTO_CHECK|READY_FOR_PUBLICATION)
      die "Version versionId=${vid} is ${vstatus} — wait for it to finish before publishing ${TAG}"
      ;;
  esac
done <<< "${VERSION_ROWS}"

if [ -z "${HAS_ACTIVE}" ]; then
  {
    echo "ERROR: у приложения ${PACKAGE} в RuStore нет активной версии —"
    echo "       RuStore Public API требует ≥1 активную версию для создания черновика."
    echo "       Первую версию публикуй вручную в RuStore Консоли"
    echo "       (https://www.rustore.ru/developer): исправь замечания модератора,"
    echo "       загрузи исправленный AAB и отправь на модерацию заново."
    if [ -n "${VERSION_ROWS}" ]; then
      echo "       Текущие версии:"
      while read -r rvid rvstatus; do
        [ -n "${rvid}" ] && echo "         versionId=${rvid} status=${rvstatus}"
      done <<< "${VERSION_ROWS}"
    else
      echo "       Версий не найдено — проверь RUSTORE_PACKAGE_NAME (${PACKAGE})."
    fi
  } >&2
  exit 1
fi

# --- whatsNew из CHANGELOG.md секции «## <version>» (<= 5000 символов) --------

# Секция версии целиком; пустые строки по краям выкидываем, длину держим
# ≤5000 символов обрезкой по границам строк (не режет UTF-8).
# Заголовки сравниваем по полям ($1=="##", $2==version) — без regex-экранирования.
extract_whats_new() {
  local ver="$1" file="$2"
  [ -f "${file}" ] || return 0
  awk -v ver="${ver}" '
    $1 == "##" && !found && $2 == ver { found = 1; next }
    found && $1 == "##" { exit }
    found { lines[++n] = $0 }
    END {
      first = 1
      while (first <= n && lines[first] ~ /^[[:space:]]*$/) first++
      last = n
      while (last >= first && lines[last] ~ /^[[:space:]]*$/) last--
      len = 0
      for (i = first; i <= last; i++) {
        add = length(lines[i]) + (i > first ? 1 : 0)
        if (len + add > 5000) break
        if (i > first) printf "\n"
        printf "%s", lines[i]
        len += add
      }
    }
  ' "${file}"
}

WHATS_NEW="$(extract_whats_new "${VERSION}" "${CHANGELOG_FILE}" || true)"
if [ -z "${WHATS_NEW//[[:space:]]/}" ]; then
  echo "WARN: no CHANGELOG section '## ${VERSION}' — using default whatsNew" >&2
  WHATS_NEW="Обновление приложения до версии ${VERSION}"
fi

json_escape_file() { # file → JSON string body (без кавычек), \n между строками
  awk 'BEGIN { ORS = "" }
    {
      gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\t/, "\\t"); gsub(/\r/, "")
      if (NR > 1) printf "\\n"
      printf "%s", $0
    }' "$1"
}

printf '%s' "${WHATS_NEW}" > "${WORK}/whats_new.txt"
MODER_INFO="${RUSTORE_MODER_INFO:-Автопубликация релиза ${TAG} через GitLab CI}"
printf '%s' "${MODER_INFO}" > "${WORK}/moder_info.txt"
WHATS_NEW_ESC="$(json_escape_file "${WORK}/whats_new.txt")"
MODER_INFO_ESC="$(json_escape_file "${WORK}/moder_info.txt")"

PAYLOAD="$(printf '{"whatsNew":"%s","publishType":"%s","moderInfo":"%s"' \
  "${WHATS_NEW_ESC}" "${PUBLISH_TYPE}" "${MODER_INFO_ESC}")"
if [ "${PUBLISH_TYPE}" = "DELAYED" ]; then
  PAYLOAD="$(printf '%s,"publishDateTime":"%s"' "${PAYLOAD}" "${RUSTORE_PUBLISH_DATETIME}")"
fi
PAYLOAD="${PAYLOAD}}"

# --- Создание черновика версии ------------------------------------------------

log "Creating draft version ${VERSION} (publishType=${PUBLISH_TYPE})"
api_call POST "${API}/public/v1/application/${PACKAGE}/version" \
  -H 'Content-Type: application/json' --data "${PAYLOAD}"
expect_ok "create draft version"

VERSION_ID="$(grep -oE '"body"[[:space:]]*:[[:space:]]*[0-9]+' "${HTTP_OUT}" | head -1 | grep -oE '[0-9]+$' || true)"
[ -n "${VERSION_ID}" ] || die "Draft created but versionId missing in response: $(head -c 1000 "${HTTP_OUT}")"
log "Draft created: versionId=${VERSION_ID}"

# --- Загрузка AAB (≤5 ГБ, один файл на версию) --------------------------------

log "Uploading AAB: ${AAB_PATH}"
api_call POST "${API}/public/v1/application/${PACKAGE}/version/${VERSION_ID}/aab" \
  --max-time 3600 --form "file=@${AAB_PATH}"
expect_ok "upload AAB"
log "AAB uploaded"

# --- Отправка на модерацию -----------------------------------------------------

log "Sending version versionId=${VERSION_ID} to moderation (priorityUpdate=${PRIORITY})"
api_call POST "${API}/public/v1/application/${PACKAGE}/version/${VERSION_ID}/commit?priorityUpdate=${PRIORITY}"
expect_ok "commit to moderation"

echo ""
echo "✅ RuStore: version versionId=${VERSION_ID} (${TAG}) sent to moderation"
echo "   package=${PACKAGE} publishType=${PUBLISH_TYPE} file=$(basename "${AAB_PATH}")"
echo "   Console: https://www.rustore.ru/developer"
echo "   Status:  GET /public/v1/application/${PACKAGE}/version?ids=${VERSION_ID}"
