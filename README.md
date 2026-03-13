# opencode-demo

Simple opencode setup scripts and configuration.

## Usage

Run start script:

```bash
./start-opencode.sh
```

Stop opencode:

```bash
./stop-opencode.sh
```

## Configuration

Create environment file from example:

```bash
cp .env.example .env
# Edit .env and set OPENCODE_SERVER_PASSWORD
```

Then source it (or pass variables directly):

```bash
source .env
./start-opencode.sh
```
