#!/bin/bash
# ScreenProtectorKit (CocoaPods) ships ScreenPreventerKit.xcframework without dSYM.
# Xcode Organizer then fails "Upload Symbols". Generate dSYM from the embedded binary.

set +e

APP_FW="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Frameworks/ScreenPreventerKit.framework/ScreenPreventerKit"

if [[ ! -f "$APP_FW" ]]; then
  echo "[generate_screen_preventer_dsym] Skip: no binary at $APP_FW"
  exit 0
fi

if [[ -z "${DWARF_DSYM_FOLDER_PATH:-}" ]]; then
  echo "[generate_screen_preventer_dsym] Skip: DWARF_DSYM_FOLDER_PATH unset"
  exit 0
fi

mkdir -p "${DWARF_DSYM_FOLDER_PATH}"
OUT="${DWARF_DSYM_FOLDER_PATH}/ScreenPreventerKit.framework.dSYM"
rm -rf "$OUT"

if dsymutil "$APP_FW" -o "$OUT"; then
  echo "[generate_screen_preventer_dsym] OK: $OUT"
else
  echo "[generate_screen_preventer_dsym] warning: dsymutil failed (non-fatal)"
fi

exit 0
