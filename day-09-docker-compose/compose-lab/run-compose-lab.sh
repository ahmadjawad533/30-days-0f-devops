#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Ensure Docker client is available (version check only)
if ! docker --version >/dev/null 2>&1; then
  echo "Docker client not found. Install Docker CLI to proceed." >&2
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose plugin not found. Install Docker Compose to proceed." >&2
  exit 1
fi

# Verify required host port is free
if ss -tln | grep -q "18100"; then
  echo "Port 18100 is already in use. Free it before running the lab." >&2
  exit 1
fi

# Ensure .env exists; if not, copy from example
if [[ ! -f "$PROJECT_ROOT/.env" ]]; then
  if [[ -f "$PROJECT_ROOT/.env.example" ]]; then
    cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
    echo ".env created from .env.example. Edit the password before starting the lab."
  else
    echo "Missing .env and .env.example. Cannot continue." >&2
    exit 1
  fi
fi

# Bring up the compose stack
cd "$PROJECT_ROOT"
# Use project name to avoid collisions
export COMPOSE_PROJECT_NAME=lab09
docker compose -f compose.yaml up -d

# Wait for healthchecks (max 60s)
for i in {1..12}; do
  if curl -sSf http://127.0.0.1:18100/health >/dev/null; then
    echo "Web service healthcheck passed."
    break
  fi
  echo "Waiting for web service healthcheck…"
  sleep 5
done

echo "Lab is running. Access the web service at http://127.0.0.1:18100/"
