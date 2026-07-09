#!/usr/bin/env bash
# Copy release APKs to dist/android with UIClone artifact names.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

OUT_DIR="${1:-build/app/outputs/flutter-apk}"
DIST_DIR="${2:-dist/android}"
LABEL="${APP_RELEASE_LABEL:?APP_RELEASE_LABEL not set (e.g. v1.0.0)}"
ABIS="${ANDROID_CI_ABIS:-arm64-v8a,armeabi-v7a,x86_64}"
INCLUDE_UNIVERSAL="${ANDROID_CI_INCLUDE_UNIVERSAL:-true}"
MAX_APKS="${ANDROID_CI_MAX_APKS:-4}"
MAX_TOTAL_MB="${ANDROID_CI_MAX_TOTAL_MB:-500}"
PREFIX="${ARTIFACT_PREFIX:-UIClone}"

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"
shopt -s nullglob

should_copy_abi() {
  local abi="$1"
  local part
  IFS=',' read -ra parts <<< "${ABIS}"
  for part in "${parts[@]}"; do
    part="${part// /}"
    if [ "${part}" = "${abi}" ]; then
      return 0
    fi
  done
  return 1
}

declare -a COPIED_PATHS=()

copy_apk() {
  local src="$1"
  local dest_name="$2"
  cp "${src}" "${DIST_DIR}/${dest_name}"
  COPIED_PATHS+=("${DIST_DIR}/${dest_name}")
  echo "Artifact: ${dest_name} ($(du -h "${src}" | cut -f1))"
}

for apk in "${OUT_DIR}"/*.apk; do
  base="$(basename "${apk}")"
  case "${base}" in
    *-debug.apk)
      echo "ERROR: Debug APK in build output: ${base}. Run scripts/flutter_build_release.sh" >&2
      exit 1
      ;;
    app-release.apk)
      if [ "${INCLUDE_UNIVERSAL}" = "true" ]; then
        copy_apk "${apk}" "${PREFIX}-android-${LABEL}-universal.apk"
      elif should_copy_abi "arm64-v8a"; then
        echo "Single-ABI release APK (${base}) → arm64-v8a artifact"
        copy_apk "${apk}" "${PREFIX}-android-${LABEL}-arm64-v8a.apk"
      else
        echo "Skip ${base} (universal disabled)"
      fi
      ;;
    app-armeabi-v7a-release.apk)
      if should_copy_abi "armeabi-v7a"; then
        copy_apk "${apk}" "${PREFIX}-android-${LABEL}-armeabi-v7a.apk"
      fi
      ;;
    app-arm64-v8a-release.apk)
      if should_copy_abi "arm64-v8a"; then
        copy_apk "${apk}" "${PREFIX}-android-${LABEL}-arm64-v8a.apk"
      fi
      ;;
    app-x86_64-release.apk)
      if should_copy_abi "x86_64"; then
        copy_apk "${apk}" "${PREFIX}-android-${LABEL}-x86_64.apk"
      fi
      ;;
    *)
      echo "Skip unknown APK: ${base}"
      ;;
  esac
done

if [ "${#COPIED_PATHS[@]}" -eq 0 ]; then
  echo "ERROR: No APK copied to ${DIST_DIR}. Check build output in ${OUT_DIR}" >&2
  ls -la "${OUT_DIR}" || true
  exit 1
fi

total_kb=$(du -sk "${DIST_DIR}" | cut -f1)
total_mb=$((total_kb / 1024))
echo "Artifacts in ${DIST_DIR} (total ~${total_mb} MB):"
du -h "${DIST_DIR}"/*

if [ "${total_mb}" -gt "${MAX_TOTAL_MB}" ]; then
  echo "ERROR: dist/android is ${total_mb} MB (limit ${MAX_TOTAL_MB} MB)." >&2
  exit 1
fi
