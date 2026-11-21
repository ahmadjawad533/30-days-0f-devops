#!/usr/bin/env bash
set -euo pipefail

# Ensure we are in the day-09 directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Path to requirements files
REQ_IN="$PROJECT_ROOT/app/requirements.in"
REQ_OUT="$PROJECT_ROOT/app/requirements.txt"

# Create a temporary virtual environment
VENV_DIR="$PROJECT_ROOT/tmp/venv"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# Upgrade pip and install from requirements.in
pip install --upgrade pip
pip install -r "$REQ_IN"
# Freeze exact versions
pip freeze > "$REQ_OUT"

# Cleanup
deactivate
rm -rf "$VENV_DIR"

echo "Pinned requirements written to $REQ_OUT"
