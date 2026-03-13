#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-up}"

REMOTE_USER="${OPENCODE_REMOTE_USER:-openclaw}"
REMOTE_HOST="${OPENCODE_REMOTE_HOST:-openclaw}"
REMOTE="${REMOTE_USER}@${REMOTE_HOST}"

LOCAL_MOUNT="${OPENCODE_LOCAL_MOUNT:-$HOME/work}"
REMOTE_DIR="${OPENCODE_REMOTE_DIR:-work}"
REMOTE_PATH="/home/${REMOTE_USER}/${REMOTE_DIR}"

LOCAL_PORT="${OPENCODE_LOCAL_PORT:-8080}"
REMOTE_PORT="${OPENCODE_REMOTE_PORT:-8080}"

OPENCODE_PASSWORD="${OPENCODE_SERVER_PASSWORD:-}"
OPENCODE_WEB_EXTRA_ARGS="${OPENCODE_WEB_EXTRA_ARGS:-}"

usage() {
  cat <<USAGE
Usage: ./opencode.sh <command>

Commands:
  up      Mount, start remote web, and open tunnel
  down    Stop tunnel, unmount, and stop remote web
  status  Show mount/tunnel/remote state
USAGE
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERR] required command not found: $1"
    exit 1
  fi
}

tunnel_pattern() {
  echo "ssh .* -L ${LOCAL_PORT}:localhost:${REMOTE_PORT} .*${REMOTE}"
}

is_tunnel_running() {
  pgrep -af "$(tunnel_pattern)" >/dev/null
}

is_remote_running() {
  ssh -n -o BatchMode=yes "$REMOTE" "ss -ltn | grep -q ':${REMOTE_PORT} '" </dev/null
}

ensure_password() {
  if [[ -n "$OPENCODE_PASSWORD" ]]; then
    return
  fi

  if [[ ! -t 0 ]]; then
    echo "[ERR] OPENCODE_SERVER_PASSWORD is not set and no interactive terminal is available"
    echo "[ERR] Set OPENCODE_SERVER_PASSWORD before running 'up' in non-interactive mode"
    exit 1
  fi

  read -r -s -p "Enter OPENCODE server password: " OPENCODE_PASSWORD
  echo

  if [[ -z "$OPENCODE_PASSWORD" ]]; then
    echo "[ERR] Password cannot be empty"
    exit 1
  fi
}

up() {
  require_command ssh
  require_command sshfs
  require_command mountpoint

  ensure_password

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
    # Load common shell startup files so the browser session has a command
    # environment closer to what users see in their interactive terminals.
    [ -f \"\$HOME/.profile\" ] && . \"\$HOME/.profile\"
    [ -f \"\$HOME/.bash_profile\" ] && . \"\$HOME/.bash_profile\"
    [ -f \"\$HOME/.bashrc\" ] && . \"\$HOME/.bashrc\"

    export PATH=\"\$HOME/.local/bin:\$PATH\"

    if ss -ltn | grep -q \":${REMOTE_PORT} \"; then
      echo \"[OK] something already listens on port ${REMOTE_PORT}\"
    else
      echo \"[INFO] starting opencode on port ${REMOTE_PORT}\"
      export OPENCODE_SERVER_PASSWORD=\"${OPENCODE_PASSWORD}\"
      nohup opencode web --port ${REMOTE_PORT} --hostname 127.0.0.1 \
        ${OPENCODE_WEB_EXTRA_ARGS} \
        >/tmp/opencode-web.log 2>&1 < /dev/null &
      sleep 3
      ss -ltn | grep -q \":${REMOTE_PORT} \" \
        && echo \"[OK] opencode started\" \
        || { echo \"[ERR] opencode failed\"; tail -100 /tmp/opencode-web.log; exit 1; }
    fi
  '" </dev/null

  echo "[INFO] ensuring local SSH tunnel is running"
  if is_tunnel_running; then
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
}

down() {
  require_command ssh
  require_command mountpoint

  echo "[INFO] stopping local SSH tunnel on port $LOCAL_PORT"
  pkill -f "$(tunnel_pattern)" 2>/dev/null || true

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
}

status() {
  require_command mountpoint

  if mountpoint -q "$LOCAL_MOUNT"; then
    echo "[OK] mounted: $LOCAL_MOUNT"
  else
    echo "[WARN] not mounted: $LOCAL_MOUNT"
  fi

  if is_tunnel_running; then
    echo "[OK] tunnel running: localhost:${LOCAL_PORT} -> ${REMOTE}:${REMOTE_PORT}"
  else
    echo "[WARN] tunnel not running on localhost:${LOCAL_PORT}"
  fi

  if is_remote_running; then
    echo "[OK] remote listener found on ${REMOTE}:${REMOTE_PORT}"
  else
    echo "[WARN] no remote listener on ${REMOTE}:${REMOTE_PORT}"
  fi
}

case "$COMMAND" in
  up|down|status)
    "$COMMAND"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "[ERR] unknown command: $COMMAND"
    usage
    exit 1
    ;;
esac
