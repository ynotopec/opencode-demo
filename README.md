# opencode-demo

Minimal scripts to mount a remote workspace, run `opencode web`, and expose it locally.

## Quick start

```bash
cp .env.example .env
source .env
make up
```

Open: <http://localhost:8080>

## Commands

Use either `make` (recommended) or scripts directly:

- `make up` / `./opencode.sh up` – mount + start remote web + open tunnel
- `make status` / `./opencode.sh status` – show mount/tunnel/remote status
- `make down` / `./opencode.sh down` – stop tunnel + unmount + stop remote web
- `make check` – syntax-check shell scripts

Compatibility wrappers are still available:

```bash
./start-opencode.sh
./stop-opencode.sh
```

## Configuration

Environment variables (optional unless noted):

- `OPENCODE_SERVER_PASSWORD` (**recommended**) password used when starting remote `opencode web`
- `OPENCODE_REMOTE_USER` (default: `openclaw`)
- `OPENCODE_REMOTE_HOST` (default: `openclaw`)
- `OPENCODE_REMOTE_DIR` (default: `work`)
- `OPENCODE_LOCAL_MOUNT` (default: `$HOME/work`)
- `OPENCODE_LOCAL_PORT` (default: `8080`)
- `OPENCODE_REMOTE_PORT` (default: `8080`)
