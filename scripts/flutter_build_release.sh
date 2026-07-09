#!/usr/bin/env bash
# Production Flutter build (release mode) for UI Clone.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

read_version() {
  grep '^version:' pubspec.yaml | awk '{print $2}'
}

reject_debug_args() {
  for arg in "$@"; do
    case "$arg" in
      --debug|debug)
        echo "ERROR: Debug build is not allowed. Remove --debug and use this script." >&2
        exit 1
        ;;
      --profile|profile)
        echo "ERROR: Profile build is not allowed for release artifacts." >&2
        exit 1
        ;;
    esac
  done
}

warn_release_signing() {
  if [ ! -f "${ROOT}/android/key.properties" ]; then
    echo "WARNING: android/key.properties not found — Flutter builds in --release mode,"
    echo "         but APK will be signed with the debug keystore (not for store publish)."
    echo "         See docs/release-build.md and android/key.properties.example."
  fi
}

verify_android_release_output() {
  local dir="${ROOT}/build/app/outputs/flutter-apk"
  shopt -s nullglob
  local release_apks=("${dir}"/*-release*.apk)

  if [ "${#release_apks[@]}" -eq 0 ]; then
    echo "ERROR: No *-release*.apk in ${dir}. Build may have run in debug mode." >&2
    ls -la "${dir}" 2>/dev/null || true
    exit 1
  fi

  if [ -f "${dir}/app-debug.apk" ] && [ ! -f "${dir}/app-release.apk" ]; then
    echo "ERROR: Only app-debug.apk found — expected release artifact." >&2
    exit 1
  fi

  echo "OK: Flutter release APK(s):"
  for apk in "${release_apks[@]}"; do
    echo "  - $(basename "${apk}") ($(du -h "${apk}" | cut -f1))"
  done
}

verify_appbundle_output() {
  local aab="${ROOT}/build/app/outputs/bundle/release/app-release.aab"
  if [ ! -f "${aab}" ]; then
    echo "ERROR: Missing ${aab}" >&2
    exit 1
  fi
  echo "OK: ${aab} ($(du -h "${aab}" | cut -f1))"
}

ensure_codegen() {
  if [ "${SKIP_CODEGEN:-0}" = "1" ]; then
    echo "SKIP_CODEGEN=1 — skipping build_runner"
    return
  fi
  echo "Running build_runner (freezed / json_serializable)…"
  dart run build_runner build --delete-conflicting-outputs
}

APP_VERSION="$(read_version)"
echo "Building UI Clone ${APP_VERSION} in --release mode"

PLATFORM="${1:?Usage: $0 <apk|android-split|appbundle|ios> [extra flutter build args...]}"
shift || true
reject_debug_args "$@"

case "$PLATFORM" in
  android|apk)
    warn_release_signing
    flutter pub get
    ensure_codegen
    flutter build apk --release "$@"
    verify_android_release_output
    ;;
  android-split)
    warn_release_signing
    flutter pub get
    ensure_codegen
    flutter build apk --release --split-per-abi "$@"
    verify_android_release_output
    ;;
  appbundle|aab)
    warn_release_signing
    flutter pub get
    ensure_codegen
    flutter build appbundle --release "$@"
    verify_appbundle_output
    ;;
  ios)
    flutter pub get
    ensure_codegen
    flutter build ios --release --no-codesign "$@"
    echo "NOTE: Full screen capture of other apps is Android-only."
    echo "      iOS build is for UI / offline prompt flow only."
    ;;
  *)
    echo "Unknown platform: ${PLATFORM}" >&2
    echo "Usage: $0 <apk|android-split|appbundle|ios> [extra flutter build args...]" >&2
    exit 1
    ;;
esac

echo "Done: ${PLATFORM} built with flutter build --release"
