#!/usr/bin/env bash
set -euo pipefail

# Pull latest images (per .env) and restart the stack.
#
# Usage:
#   ./pull_and_restart.sh            # defaults to standAlone
#   ./pull_and_restart.sh standAlone
#   ./pull_and_restart.sh distributed/main
#   ./pull_and_restart.sh distributed/judgeserver
#   ./pull_and_restart.sh standAlone --no-pull

STACK_DIR="${1:-standAlone}"
NO_PULL="${2:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$ROOT_DIR/$STACK_DIR"

if [[ ! -f "$TARGET_DIR/docker-compose.yml" ]]; then
  echo "ERROR: docker-compose.yml not found: $TARGET_DIR" >&2
  exit 1
fi

cd "$TARGET_DIR"

# Ensure backwards-compatible data directory names for standAlone deployments.
# Some historical scripts/configs reference `hoj/` while newer setups use `hbutoj/`.
# We create a missing counterpart symlink based on whichever directory exists.
if [[ "$STACK_DIR" == "standAlone" ]]; then
  if [[ -d "hbutoj" && ! -e "hoj" ]]; then
    ln -s "hbutoj" "hoj"
  elif [[ -d "hoj" && ! -e "hbutoj" ]]; then
    ln -s "hoj" "hbutoj"
  fi
  # Compatibility for a historical typo path.
  if [[ -e "hbutoj" && ! -e "hbutoh" ]]; then
    ln -s "hbutoj" "hbutoh"
  fi
fi

if [[ "$NO_PULL" == "--no-pull" ]]; then
  echo "==> Skipping pull (using local images): $TARGET_DIR"
else
  echo "==> Pulling images in: $TARGET_DIR"
  docker compose pull
fi

echo "==> Restarting stack"
docker compose up -d

echo "==> Done"
