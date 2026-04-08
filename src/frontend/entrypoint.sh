#!/bin/sh
set -e

: "${SERVER_NAME:=localhost}"
: "${BACKEND_SERVER_HOST:=127.0.0.1}"
: "${BACKEND_SERVER_PORT:=6688}"

envsubst '${SERVER_NAME} ${BACKEND_SERVER_HOST} ${BACKEND_SERVER_PORT}' \
  < /etc/nginx/conf.d/default.conf.template \
  > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
