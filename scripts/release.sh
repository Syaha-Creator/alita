#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# release.sh — Satu script untuk semua release Alita Pricelist
# ─────────────────────────────────────────────────────────────────────────────
# Usage:
#   ./scripts/release.sh             → menu interaktif (pilih iOS/Android/keduanya)
#   ./scripts/release.sh ios         → iOS saja
#   ./scripts/release.sh android     → Android AAB saja
#   ./scripts/release.sh android apk → Android APK saja
#   ./scripts/release.sh all         → iOS + Android sekaligus
#   ./scripts/release.sh --deploy    → deploy version.json setelah app live
# ─────────────────────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

PUBSPEC="$PROJECT_ROOT/pubspec.yaml"
VERSION_JSON="$PROJECT_ROOT/hosting/version.json"
ENV_FILE="$PROJECT_ROOT/.env"

# ── Helpers ──────────────────────────────────────────────────────────────────
get_version() { grep '^version:' "$PUBSPEC" | sed 's/version: //' | cut -d+ -f1; }
get_build()   { grep '^version:' "$PUBSPEC" | sed 's/version: //' | cut -d+ -f2; }

read_env() {
  local val
  val=$(grep -E "^${1}=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2-)
  val="${val#\"}"; val="${val%\"}"; val="${val#\'}"; val="${val%\'}"
  echo "$val"
}

encode_kv() { echo -n "$1" | base64 | tr -d '\n'; }

# ── Load .env untuk dart-define ───────────────────────────────────────────────
load_dart_defines() {
  local keys="API_BASE_URL CLIENT_ID_ANDROID CLIENT_SECRET_ANDROID CLIENT_ID_IOS CLIENT_SECRET_IOS COMFORTA_ACCESS_TOKEN COMFORTA_CLIENT_ID COMFORTA_CLIENT_SECRET"
  DART_DEFINES=()
  for k in $keys; do
    local v
    v=$(read_env "$k")
    [[ -n "$v" ]] && DART_DEFINES+=(--dart-define="$k=$v")
  done
  if [[ ${#DART_DEFINES[@]} -eq 0 ]]; then
    echo "Error: .env tidak ditemukan atau kosong. Isi .env terlebih dahulu."
    exit 1
  fi
}

# ── Generate DartSecrets.xcconfig untuk Xcode ────────────────────────────────
gen_xcconfig() {
  local XCCONFIG="$PROJECT_ROOT/ios/Flutter/DartSecrets.xcconfig"
  local API_BASE_URL CLIENT_ID_IOS CLIENT_SECRET_IOS
  local COMFORTA_ACCESS_TOKEN COMFORTA_CLIENT_ID COMFORTA_CLIENT_SECRET

  API_BASE_URL=$(read_env API_BASE_URL)
  CLIENT_ID_IOS=$(read_env CLIENT_ID_IOS)
  CLIENT_SECRET_IOS=$(read_env CLIENT_SECRET_IOS)
  COMFORTA_ACCESS_TOKEN=$(read_env COMFORTA_ACCESS_TOKEN)
  COMFORTA_CLIENT_ID=$(read_env COMFORTA_CLIENT_ID)
  COMFORTA_CLIENT_SECRET=$(read_env COMFORTA_CLIENT_SECRET)

  if [[ -z "$API_BASE_URL" || -z "$CLIENT_ID_IOS" || -z "$CLIENT_SECRET_IOS" ]]; then
    echo "Error: API_BASE_URL / CLIENT_ID_IOS / CLIENT_SECRET_IOS kosong di .env"
    exit 1
  fi

  local DEFINES=""
  append() { [[ -n "$2" ]] && DEFINES="${DEFINES:+$DEFINES,}$(encode_kv "$1=$2")"; }
  append API_BASE_URL          "$API_BASE_URL"
  append CLIENT_ID_IOS         "$CLIENT_ID_IOS"
  append CLIENT_SECRET_IOS     "$CLIENT_SECRET_IOS"
  append COMFORTA_ACCESS_TOKEN "$COMFORTA_ACCESS_TOKEN"
  append COMFORTA_CLIENT_ID    "$COMFORTA_CLIENT_ID"
  append COMFORTA_CLIENT_SECRET "$COMFORTA_CLIENT_SECRET"

  cat > "$XCCONFIG" <<EOF
// AUTO-GENERATED — JANGAN DI-COMMIT
// Regenerate: ./scripts/release.sh ios
DART_DEFINES=$DEFINES
EOF
  echo "  ✓ DartSecrets.xcconfig ter-generate"
}

# ── Bump versi ────────────────────────────────────────────────────────────────
bump_version() {
  OLD_VERSION=$(get_version)
  OLD_BUILD=$(get_build)
  NEW_BUILD=$((OLD_BUILD + 1))
  IFS='.' read -r MAJOR MINOR PATCH <<< "$OLD_VERSION"
  NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"

  sed -i '' "s/^version: .*/version: $NEW_VERSION+$NEW_BUILD/" "$PUBSPEC"
  sed -i '' "s/\"minimum_version\": \"$OLD_VERSION\"/\"minimum_version\": \"$NEW_VERSION\"/g" "$VERSION_JSON"
  echo "  ✓ Versi: $OLD_VERSION+$OLD_BUILD → $NEW_VERSION+$NEW_BUILD"
}

# ── Clean + pub get (shared) ──────────────────────────────────────────────────
clean_and_get() {
  echo ""
  echo "▸ flutter clean + pub get"
  flutter clean
  flutter pub get
}

# ════════════════════════════════════════════════════════════════════════════
# MODE: --deploy
# ════════════════════════════════════════════════════════════════════════════
if [[ "$1" == "--deploy" ]]; then
  CURRENT=$(get_version)
  echo "Deploying version.json (minimum_version=$CURRENT) ke Firebase..."
  firebase deploy --only hosting
  echo ""
  echo "✓ Live: https://alita-pricelist-12d76.web.app/version.json"
  echo "  User iOS lama akan dapat notifikasi update ke $CURRENT."
  exit 0
fi

# ════════════════════════════════════════════════════════════════════════════
# Pilih platform
# ════════════════════════════════════════════════════════════════════════════
PLATFORM="${1:-}"
SUBTYPE="${2:-}"

if [[ -z "$PLATFORM" ]]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Alita Pricelist — Release"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  1) iOS        (App Store)"
  echo "  2) Android    (Play Store AAB)"
  echo "  3) Keduanya"
  echo ""
  read -p "  Pilihan (1/2/3): " CHOICE
  case "$CHOICE" in
    1) PLATFORM="ios"     ;;
    2) PLATFORM="android" ;;
    3) PLATFORM="all"     ;;
    *) echo "Pilihan tidak valid." && exit 1 ;;
  esac
fi

# ════════════════════════════════════════════════════════════════════════════
# Konfirmasi & bump versi
# ════════════════════════════════════════════════════════════════════════════
OLD_VERSION=$(get_version); OLD_BUILD=$(get_build)
IFS='.' read -r MA MI PA <<< "$OLD_VERSION"
PREVIEW="$MA.$MI.$((PA+1))+$((OLD_BUILD+1))"

echo ""
echo "  Platform : $PLATFORM"
echo "  Versi    : $OLD_VERSION+$OLD_BUILD → $PREVIEW"
echo ""
read -p "  Lanjutkan? (y/N) " CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && echo "Dibatalkan." && exit 0

bump_version
load_dart_defines
clean_and_get

# ════════════════════════════════════════════════════════════════════════════
# Build iOS
# ════════════════════════════════════════════════════════════════════════════
build_ios() {
  echo ""
  echo "══════════ iOS ══════════"
  echo "▸ Hapus Podfile.lock + pod install..."
  rm -f ios/Podfile.lock && rm -rf ios/Pods ios/.symlinks
  cd ios && pod install && cd ..
  echo "▸ Generate DartSecrets.xcconfig..."
  gen_xcconfig
  echo "▸ flutter build ipa --release..."
  flutter build ipa --release "${DART_DEFINES[@]}"
  IOS_DONE=1
}

# ════════════════════════════════════════════════════════════════════════════
# Build Android
# ════════════════════════════════════════════════════════════════════════════
build_android() {
  echo ""
  echo "══════════ Android ══════════"
  if [[ "$SUBTYPE" == "apk" ]]; then
    echo "▸ flutter build apk --release..."
    flutter build apk --release "${DART_DEFINES[@]}"
    ANDROID_OUT="build/app/outputs/flutter-apk/app-release.apk"
  else
    echo "▸ flutter build appbundle --release..."
    flutter build appbundle --release "${DART_DEFINES[@]}"
    ANDROID_OUT="build/app/outputs/bundle/release/app-release.aab"
  fi
  ANDROID_DONE=1
}

[[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]     && build_ios
[[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]] && build_android

# ════════════════════════════════════════════════════════════════════════════
# Summary
# ════════════════════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Build $NEW_VERSION+$NEW_BUILD selesai!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ -n "${IOS_DONE:-}" ]]; then
  echo "  iOS → Xcode: Window → Organizer → Distribute App"
  open -a Xcode "$PROJECT_ROOT/build/ios/archive/Runner.xcarchive" 2>/dev/null || true
fi
if [[ -n "${ANDROID_DONE:-}" ]]; then
  echo "  Android → Upload: https://play.google.com/console"
  echo "  File: $ANDROID_OUT"
  open "$(dirname "$PROJECT_ROOT/$ANDROID_OUT")" 2>/dev/null || true
fi

echo ""
echo "  Setelah app live di store, jalankan:"
echo "  ./scripts/release.sh --deploy"
echo ""
