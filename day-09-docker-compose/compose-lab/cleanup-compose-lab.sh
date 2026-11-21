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

# Bring down the compose stack, remove volumes and orphans
cd "$PROJECT_ROOT"
export COMPOSE_PROJECT_NAME=lab09
docker compose -f compose.yaml down -v --remove-orphans

# Remove generated .env if it was created by run script
if [[ -f "$PROJECT_ROOT/.env" && ! -f "$PROJECT_ROOT/.env.example" ]]; then
  rm -f "$PROJECT_ROOT/.env"
  echo "Removed generated .env file."
fi

# Cleanup any temporary outputs folder if present
if [[ -d "$PROJECT_ROOT/outputs" ]]; then
  rm -rf "$PROJECT_ROOT/outputs"
  echo "Removed outputs directory."
fi

echo "Cleanup complete. Lab resources have been removed."
