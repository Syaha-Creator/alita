#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# use-env.sh — Switch local `.env` antara staging dan production
# ─────────────────────────────────────────────────────────────────────────────
# Usage:
#   ./scripts/use-env.sh staging      # copy .env.staging → .env (untuk flutter run)
#   ./scripts/use-env.sh production   # copy .env.production → .env
#   ./scripts/use-env.sh status       # tampilkan APP_ENV + API_BASE_URL aktif
# ─────────────────────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

ENV_ACTIVE="$PROJECT_ROOT/.env"

read_key() {
  local file="$1" key="$2"
  local val
  val=$(grep -E "^${key}=" "$file" 2>/dev/null | head -1 | cut -d= -f2-)
  val="${val#\"}"; val="${val%\"}"; val="${val#\'}"; val="${val%\'}"
  echo "$val"
}

show_status() {
  if [[ ! -f "$ENV_ACTIVE" ]]; then
    echo "  .env belum ada. Jalankan: ./scripts/use-env.sh staging"
    exit 1
  fi
  local app_env base
  app_env=$(read_key "$ENV_ACTIVE" APP_ENV)
  base=$(read_key "$ENV_ACTIVE" API_BASE_URL)
  echo "  Aktif (.env):"
  echo "    APP_ENV      = ${app_env:-"(infer dari URL)"}"
  echo "    API_BASE_URL = $base"
}

TARGET="${1:-}"
case "$TARGET" in
  staging|production)
    SRC="$PROJECT_ROOT/.env.$TARGET"
    if [[ ! -f "$SRC" ]]; then
      echo "Error: $SRC tidak ditemukan."
      echo "Buat dulu dari template:"
      echo "  cp .env.example .env.$TARGET"
      echo "  # lalu isi secrets + set API_BASE_URL / APP_ENV=$TARGET"
      exit 1
    fi
    cp "$SRC" "$ENV_ACTIVE"
    echo "✓ .env diganti dari .env.$TARGET"
    show_status
    ;;
  status|"")
    show_status
    ;;
  *)
    echo "Usage: ./scripts/use-env.sh [staging|production|status]"
    exit 1
    ;;
esac
