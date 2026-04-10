#!/bin/sh
set -eu

JAVA_OPTS="${JAVA_OPTS:-}"
SANDBOX_DIR="${SANDBOX_DIR:-/judge/.sandbox}"

arch="$(uname -m)"
case "$arch" in
  x86_64|amd64)
    SANDBOX_BIN="/judge/Sandbox-amd64-v1.8.0"
    ;;
  aarch64|arm64)
    SANDBOX_BIN="/judge/Sandbox-arm64-v1.8.0"
    ;;
  *)
    echo "Unsupported architecture for sandbox: $arch" >&2
    exit 1
    ;;
esac

if [ ! -x "$SANDBOX_BIN" ]; then
  echo "Sandbox binary not found or not executable: $SANDBOX_BIN" >&2
  exit 1
fi

mkdir -p "$SANDBOX_DIR"
mkdir -p /judge/log/judgeserver

"$SANDBOX_BIN" --dir "$SANDBOX_DIR" --release >/judge/log/judgeserver/sandbox.log 2>&1 &
SANDBOX_PID=$!

cleanup() {
  kill "$SANDBOX_PID" 2>/dev/null || true
}

trap cleanup INT TERM EXIT

for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:5050/version >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! curl -fsS http://127.0.0.1:5050/version >/dev/null 2>&1; then
  echo "Sandbox service failed to start on localhost:5050" >&2
  exit 1
fi

java $JAVA_OPTS -jar /judge/hoj-judgeServer.jar &
JAVA_PID=$!

wait "$JAVA_PID"
STATUS=$?
cleanup
exit "$STATUS"
