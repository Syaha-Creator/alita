#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# dev.sh — Jalankan app untuk development (SELALU staging)
# ─────────────────────────────────────────────────────────────────────────────
# Usage:
#   ./scripts/dev.sh                 → flutter run (staging, device/simulator default)
#   ./scripts/dev.sh -d <device_id>  → flutter run -d <device_id> (staging)
#   Semua argumen diteruskan langsung ke `flutter run`.
#
# Kenapa: `.env` aktif dipakai sebagai asset bundle (lihat pubspec.yaml).
# Script ini auto-switch `.env` ke `.env.staging` supaya dev harian tidak
# pernah "kebawa" .env.production yang masih aktif dari sesi sebelumnya.
# Untuk release production, pakai ./scripts/release.sh (default production).
# ─────────────────────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

"$SCRIPT_DIR/use-env.sh" staging

echo "▶ flutter run (staging) $*"
exec flutter run "$@"
