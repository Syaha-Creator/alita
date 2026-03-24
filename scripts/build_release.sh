#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Alita Pricelist — Release Build Script
# ─────────────────────────────────────────────────────────────────────────────
# Otomatis baca .env di project root. Jika .env tidak ada, gunakan env vars
# yang sudah di-export.
#
# Prioritas: env vars yang sudah di-set > nilai dari .env
# ─────────────────────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Load .env (hanya key yang dipakai untuk build, hindari FIREBASE_* yang kompleks)
load_env() {
  [[ ! -f .env ]] && return
  local keys="API_BASE_URL CLIENT_ID_ANDROID CLIENT_SECRET_ANDROID CLIENT_ID_IOS CLIENT_SECRET_IOS COMFORTA_ACCESS_TOKEN COMFORTA_CLIENT_ID COMFORTA_CLIENT_SECRET"
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    if [[ "$line" == *=* ]]; then
      key="${line%%=*}"; key="${key// /}"
      val="${line#*=}"; val="${val#\"}"; val="${val%\"}"
      for k in $keys; do
        if [[ "$key" == "$k" ]]; then
          export "$key=$val"
          break
        fi
      done
    fi
  done < .env
}
load_env

# Build target: apk | appbundle
TARGET="${1:-appbundle}"

# Build --dart-define args
DART_DEFINES=()

add_define() {
  local key="$1"
  local val="${!key}"
  if [[ -n "$val" ]]; then
    DART_DEFINES+=(--dart-define="$key=$val")
  fi
}

add_define API_BASE_URL
add_define CLIENT_ID_ANDROID
add_define CLIENT_SECRET_ANDROID
add_define CLIENT_ID_IOS
add_define CLIENT_SECRET_IOS
add_define COMFORTA_ACCESS_TOKEN
add_define COMFORTA_CLIENT_ID
add_define COMFORTA_CLIENT_SECRET

if [[ ${#DART_DEFINES[@]} -eq 0 ]]; then
  echo "Error: API_BASE_URL, CLIENT_ID_ANDROID/IOS, CLIENT_SECRET_ANDROID/IOS belum di-set."
  echo "  Pastikan .env ada di project root, atau export manual."
  exit 1
fi

echo "Building $TARGET with ${#DART_DEFINES[@]} dart-define(s)..."

case "$TARGET" in
  apk)
    flutter build apk --release "${DART_DEFINES[@]}"
    echo "Done: build/app/outputs/flutter-apk/app-release.apk"
    ;;
  appbundle)
    flutter build appbundle --release "${DART_DEFINES[@]}"
    echo "Done: build/app/outputs/bundle/release/app-release.aab"
    ;;
  *)
    echo "Usage: $0 <apk|appbundle>"
    exit 1
    ;;
esac
