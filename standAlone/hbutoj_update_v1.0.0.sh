#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Pulling images..."
docker compose pull

echo "Restarting services..."
docker compose up -d

echo
 echo "Status:" 
docker compose ps
