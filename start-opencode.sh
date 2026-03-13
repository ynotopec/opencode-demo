#!/usr/bin/env bash
set -euo pipefail

REMOTE_USER="openclaw"
REMOTE_HOST="openclaw"
REMOTE="${REMOTE_USER}@${REMOTE_HOST}"

LOCAL_MOUNT="$HOME/work"
REMOTE_DIR="work"
REMOTE_PATH="/home/${REMOTE_USER}/${REMOTE_DIR}"

LOCAL_PORT="8080"
REMOTE_PORT="8080"

OPENCODE_PASSWORD="${OPENCODE_SERVER_PASSWORD:-change-me-now}"

if [[ "$OPENCODE_PASSWORD" == "change-me-now" ]]; then
  echo "[WARN] OPENCODE_SERVER_PASSWORD is still using default value"
  echo "[WARN] Set OPENCODE_SERVER_PASSWORD environment variable"
fi

mkdir -p "$LOCAL_MOUNT"

echo "[INFO] ensuring remote directory exists: $REMOTE_PATH"
ssh -n -o BatchMode=yes "$REMOTE" "mkdir -p '$REMOTE_PATH'" </dev/null

echo "[INFO] ensuring sshfs mount"
if mountpoint -q "$LOCAL_MOUNT"; then
  echo "[OK] already mounted: $LOCAL_MOUNT"
else
  echo "[INFO] mounting $REMOTE:$REMOTE_PATH -> $LOCAL_MOUNT"
  sshfs \
    -o reconnect \
    -o ServerAliveInterval=15 \
    -o ServerAliveCountMax=3 \
    -o auto_unmount \
    "$REMOTE:$REMOTE_PATH" "$LOCAL_MOUNT"
  echo "[OK] mounted: $LOCAL_MOUNT"
fi

echo "[INFO] ensuring remote opencode web is running"
ssh -n -o BatchMode=yes "$REMOTE" "bash -lc '
  export PATH=\"\$HOME/.local/bin:\$PATH\"

  if ss -ltn | grep -q \":${REMOTE_PORT} \"; then
    echo \"[OK] something already listens on port ${REMOTE_PORT}\"
  else
    echo \"[INFO] starting opencode on port ${REMOTE_PORT}\"
    export OPENCODE_SERVER_PASSWORD=\"${OPENCODE_PASSWORD}\"
    nohup opencode web --port ${REMOTE_PORT} --hostname 127.0.0.1 \
      >/tmp/opencode-web.log 2>&1 < /dev/null &
    sleep 3
    ss -ltn | grep -q \":${REMOTE_PORT} \" \
      && echo \"[OK] opencode started\" \
      || { echo \"[ERR] opencode failed\"; tail -100 /tmp/opencode-web.log; exit 1; }
  fi
'" </dev/null

echo "[INFO] ensuring local SSH tunnel is running"
if pgrep -af "ssh .* -L ${LOCAL_PORT}:localhost:${REMOTE_PORT} .*${REMOTE}" >/dev/null; then
  echo "[OK] tunnel already running on localhost:${LOCAL_PORT}"
else
  ssh -fN -n \
    -o BatchMode=yes \
    -o ExitOnForwardFailure=yes \
    -L "${LOCAL_PORT}:localhost:${REMOTE_PORT}" \
    "$REMOTE" </dev/null
  echo "[OK] tunnel started on localhost:${LOCAL_PORT}"
fi

echo
echo "[DONE]"
echo "Mount : $LOCAL_MOUNT"
echo "Web   : http://localhost:${LOCAL_PORT}"
