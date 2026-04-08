#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash migrate_data_dir_hoj_to_hbutoj.sh [--dry-run] [--apply] [--allow-running] [--update-env]

What it does:
  - Copies standAlone/hoj/  -> standAlone/hbutoj/ using rsync
  - Default is --dry-run (no changes)
  - Does NOT delete or modify the source directory

Safety:
  - If --apply is used and containers are running, the script will refuse unless --allow-running is provided.

Options:
  --dry-run       Show what would be copied (default)
  --apply         Perform the copy
  --allow-running Allow --apply even if docker compose has running containers (not recommended)
  --update-env    Backup and update standAlone/.env to set HBUTOJ_DATA_DIRECTORY=./hbutoj
EOF
}

DRY_RUN=1
APPLY=0
ALLOW_RUNNING=0
UPDATE_ENV=0

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=1
      APPLY=0
      ;;
    --apply)
      DRY_RUN=0
      APPLY=1
      ;;
    --allow-running)
      ALLOW_RUNNING=1
      ;;
    --update-env)
      UPDATE_ENV=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SRC_DIR="$SCRIPT_DIR/hoj"
DST_DIR="$SCRIPT_DIR/hbutoj"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "ERROR: source directory not found: $SRC_DIR" >&2
  echo "If your data directory is elsewhere, set HBUTOJ_DATA_DIRECTORY accordingly in .env instead of running this script." >&2
  exit 1
fi

if [[ -e "$DST_DIR" && ! -d "$DST_DIR" ]]; then
  echo "ERROR: destination exists but is not a directory: $DST_DIR" >&2
  exit 1
fi

if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then
    if [[ "$APPLY" == "1" && "$ALLOW_RUNNING" == "0" ]]; then
      # If there are any containers for this compose project, treat as running.
      if docker compose -f "$SCRIPT_DIR/docker-compose.yml" ps -q | grep -q .; then
        echo "ERROR: docker compose appears to have containers for this stack." >&2
        echo "To avoid inconsistent copies, stop the stack first:" >&2
        echo "  cd $SCRIPT_DIR && docker compose down" >&2
        echo "Then re-run with --apply." >&2
        echo "If you understand the risk, re-run with --apply --allow-running." >&2
        exit 1
      fi
    fi
  fi
fi

mkdir -p "$DST_DIR"

RSYNC_ARGS=(
  -aH
  --info=progress2
)

if [[ "$DRY_RUN" == "1" ]]; then
  RSYNC_ARGS+=(--dry-run)
  echo "[DRY-RUN] Copy: $SRC_DIR/ -> $DST_DIR/"
else
  echo "[APPLY] Copy: $SRC_DIR/ -> $DST_DIR/"
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "ERROR: rsync not found. Install it first (e.g. apt-get install -y rsync)." >&2
  exit 1
fi

rsync "${RSYNC_ARGS[@]}" "$SRC_DIR/" "$DST_DIR/"

if [[ "$APPLY" == "1" && "$UPDATE_ENV" == "1" ]]; then
  ENV_FILE="$SCRIPT_DIR/.env"
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "WARN: .env not found at $ENV_FILE; skipped --update-env" >&2
  else
    TS="$(date +%Y-%m-%d-%H%M%S)"
    cp -p "$ENV_FILE" "$SCRIPT_DIR/.env.bak.$TS"

    # Ensure HBUTOJ_DATA_DIRECTORY is set to ./hbutoj
    if grep -qE '^HBUTOJ_DATA_DIRECTORY=' "$ENV_FILE"; then
      sed -i 's|^HBUTOJ_DATA_DIRECTORY=.*$|HBUTOJ_DATA_DIRECTORY=./hbutoj|' "$ENV_FILE"
    else
      printf '\nHBUTOJ_DATA_DIRECTORY=./hbutoj\n' >> "$ENV_FILE"
    fi

    echo "Updated .env (backup: .env.bak.$TS)"
  fi
fi

echo "Done."
