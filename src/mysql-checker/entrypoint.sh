#!/bin/sh
set -e

MYSQL_HOST="${MYSQL_HOST:-mysql}"
MYSQL_PORT="${MYSQL_PORT:-3306}"

if [ -z "${MYSQL_ROOT_PASSWORD:-}" ]; then
  echo "ERROR: MYSQL_ROOT_PASSWORD is required" >&2
  exit 1
fi

echo "==> mysql-checker: waiting for MySQL at ${MYSQL_HOST}:${MYSQL_PORT}"
for i in $(seq 1 60); do
  if mysqladmin ping -h "$MYSQL_HOST" -P "$MYSQL_PORT" -uroot -p"$MYSQL_ROOT_PASSWORD" --silent; then
    break
  fi
  sleep 2
done

echo "==> mysql-checker: ensuring databases exist (nacos, hoj)"
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -uroot -p"$MYSQL_ROOT_PASSWORD" \
  -e "CREATE DATABASE IF NOT EXISTS nacos DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" \
  -e "CREATE DATABASE IF NOT EXISTS hoj DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

echo "==> mysql-checker: done"

# Keep container running (compose expects a long-lived service).
tail -f /dev/null
