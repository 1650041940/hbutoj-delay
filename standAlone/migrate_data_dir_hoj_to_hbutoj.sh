#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash migrate_data_dir_hoj_to_hbutoj.sh [--dry-run] [--apply] [--allow-running] [--update-env]
  bash migrate_data_dir_hoj_to_hbutoj.sh [--dry-run] [--apply] [--allow-running] [--update-env] [--replace-mysql|--skip-mysql]

What it does:
  - Copies standAlone/hoj/  -> standAlone/hbutoj/ using rsync
  - Default is --dry-run (no changes)
  - Does NOT delete or modify the source directory

MySQL note:
  - MySQL data directories cannot be safely "merged". Overlay-copying one onto another may corrupt redo logs.
  - If both source and destination already have MySQL datadirs, you MUST choose one:
      --replace-mysql  (backup destination then replace it with source)
      --skip-mysql     (do not copy MySQL datadir)

Safety:
  - If --apply is used and containers are running, the script will refuse unless --allow-running is provided.

Options:
  --dry-run       Show what would be copied (default)
  --apply         Perform the copy
  --allow-running Allow --apply even if docker compose has running containers (not recommended)
  --update-env    Backup and update standAlone/.env to set HBUTOJ_DATA_DIRECTORY=./hbutoj
  --replace-mysql Backup destination MySQL datadir then replace it with source (recommended when migrating DB)
  --skip-mysql    Do not copy MySQL datadir
EOF
}

DRY_RUN=1
APPLY=0
ALLOW_RUNNING=0
UPDATE_ENV=0
REPLACE_MYSQL=0
SKIP_MYSQL=0

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
    --replace-mysql)
      REPLACE_MYSQL=1
      ;;
    --skip-mysql)
      SKIP_MYSQL=1
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

if [[ "$REPLACE_MYSQL" == "1" && "$SKIP_MYSQL" == "1" ]]; then
  echo "ERROR: --replace-mysql and --skip-mysql are mutually exclusive." >&2
  exit 2
fi

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

SRC_MYSQL="$SRC_DIR/data/mysql/data"
DST_MYSQL="$DST_DIR/data/mysql/data"

if [[ -d "$SRC_MYSQL" ]]; then
  if [[ -d "$DST_MYSQL" ]]; then
    # If destination has any content, require an explicit choice.
    if find "$DST_MYSQL" -mindepth 1 -maxdepth 1 2>/dev/null | grep -q .; then
      if [[ "$REPLACE_MYSQL" == "0" && "$SKIP_MYSQL" == "0" ]]; then
        echo "ERROR: Both source and destination have MySQL datadirs:" >&2
        echo "  SRC: $SRC_MYSQL" >&2
        echo "  DST: $DST_MYSQL" >&2
        echo "MySQL datadirs cannot be merged safely." >&2
        echo "Please re-run with ONE of:" >&2
        echo "  --replace-mysql   (backup DST then replace with SRC)" >&2
        echo "  --skip-mysql      (do not copy MySQL datadir)" >&2
        exit 1
      fi
    fi
  fi
fi

RSYNC_ARGS=(
  -aH
  --info=progress2
)

if [[ "$SKIP_MYSQL" == "1" || "$REPLACE_MYSQL" == "1" ]]; then
  # Copy MySQL separately (skip or replace); avoid overlay merging.
  RSYNC_ARGS+=(--exclude 'data/mysql/data/**')
fi

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

if [[ "$REPLACE_MYSQL" == "1" && -d "$SRC_MYSQL" ]]; then
  if [[ "$APPLY" == "1" ]]; then
    TS="$(date +%Y-%m-%d-%H%M%S)"
    if [[ -d "$DST_MYSQL" ]]; then
      mv "$DST_MYSQL" "${DST_MYSQL}.bak.${TS}"
      echo "Backed up destination MySQL datadir: ${DST_MYSQL}.bak.${TS}"
    fi
    mkdir -p "$DST_MYSQL"
    rsync -aH --delete "$SRC_MYSQL/" "$DST_MYSQL/"
    echo "Replaced destination MySQL datadir from source."
  else
    echo "[DRY-RUN] Would replace MySQL datadir: $DST_MYSQL <- $SRC_MYSQL"
  fi
fi

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
