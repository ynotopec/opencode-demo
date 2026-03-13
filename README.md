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

- `OPENCODE_SERVER_PASSWORD` (**optional**) password used when starting remote `opencode web`
  - If not set, `make up` / `./opencode.sh up` will securely prompt for it at startup in interactive shells
- `OPENCODE_REMOTE_USER` (default: `openclaw`)
- `OPENCODE_REMOTE_HOST` (default: `openclaw`)
- `OPENCODE_REMOTE_DIR` (default: `work`)
- `OPENCODE_LOCAL_MOUNT` (default: `$HOME/work`)
- `OPENCODE_LOCAL_PORT` (default: `8080`)
- `OPENCODE_REMOTE_PORT` (default: `8080`)
- `OPENCODE_WEB_EXTRA_ARGS` (default: empty) additional flags appended to `opencode web`

### Browser command behavior vs terminal

If commands work in your SSH terminal but fail in the web UI, use the latest script behavior:

- `opencode.sh up` now sources common shell startup files on the remote host (`~/.profile`, `~/.bash_profile`, `~/.bashrc`) before launching `opencode web`.
- This helps the browser session inherit PATH/tooling setup closer to your normal terminal.
- If needed, you can also pass explicit runtime flags through `OPENCODE_WEB_EXTRA_ARGS`.
