#!/usr/bin/env bash
set -u

REMOTE_USER="openclaw"
REMOTE_HOST="openclaw"
REMOTE="${REMOTE_USER}@${REMOTE_HOST}"

LOCAL_MOUNT="$HOME/work"
LOCAL_PORT="8080"
REMOTE_PORT="8080"

echo "[INFO] stopping local SSH tunnel on port $LOCAL_PORT"
pkill -f "ssh .* -L ${LOCAL_PORT}:localhost:${REMOTE_PORT} .*${REMOTE}" 2>/dev/null || true

echo "[INFO] unmounting $LOCAL_MOUNT"
if mountpoint -q "$LOCAL_MOUNT"; then
  fusermount -u "$LOCAL_MOUNT" 2>/dev/null || umount "$LOCAL_MOUNT" 2>/dev/null || true
else
  echo "[OK] not mounted: $LOCAL_MOUNT"
fi

echo "[INFO] stopping remote opencode"
ssh -n -o BatchMode=yes "$REMOTE" "bash -lc '
  pkill -f \"opencode web --port ${REMOTE_PORT}\" 2>/dev/null || true
  sleep 1
  pgrep -af \"opencode web --port ${REMOTE_PORT}\" >/dev/null \
    && echo \"[WARN] remote opencode may still be running\" \
    || echo \"[OK] remote opencode stopped\"
'" </dev/null

echo "[DONE]"
