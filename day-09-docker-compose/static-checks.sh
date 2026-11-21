#!/usr/bin/env bash
set -euo pipefail

# Directory for static analysis outputs
OUTPUT_DIR="$(dirname "$0")/../outputs"
mkdir -p "$OUTPUT_DIR"

# Bash syntax check for all .sh files
echo "Running bash syntax check..."
find . -name "*.sh" -print0 | while IFS= read -r -d '' script; do
  bash -n "$script" 2> "$OUTPUT_DIR/$(basename "$script").txt" || true
done

# Python syntax check for app files
if [[ -d "app" ]]; then
  echo "Running python syntax check..."
  python3 -m py_compile app/*.py 2> "$OUTPUT_DIR/python_syntax.txt" || true
fi

# Optional: check Dockerfile syntax with hadolint if available
if command -v hadolint >/dev/null 2>&1; then
  echo "Running hadolint on Dockerfile..."
  hadolint Dockerfile > "$OUTPUT_DIR/hadolint.txt" || true
fi

# Optional: shellcheck on scripts
if command -v shellcheck >/dev/null 2>&1; then
  echo "Running shellcheck..."
  shellcheck **/*.sh > "$OUTPUT_DIR/shellcheck.txt" || true
fi

# Optional: YAML lint with yamllint if available
if command -v yamllint >/dev/null 2>&1; then
  echo "Running yamllint..."
  yamllint . > "$OUTPUT_DIR/yamllint.txt" || true
fi

echo "Static checks completed. Outputs stored in $OUTPUT_DIR"
