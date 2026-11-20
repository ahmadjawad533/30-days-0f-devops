#!/usr/bin/env bash
set -u

# Utility to write a header with timestamp
log_output() {
  local file=$1
  local cmd=$2
  echo "# Command: $cmd" > "$file"
  echo "# Timestamp: $(date -u +'%Y-%m-%dT%H:%M:%SZ')" >> "$file"
  echo "# Output:" >> "$file"
  eval "$cmd" >> "$file" 2>&1 || echo "[FAILED] $cmd" >> "$file"
}

OUTPUT_DIR="$(dirname "$0")/outputs"
mkdir -p "$OUTPUT_DIR"

# 01: Python syntax check
log_output "$OUTPUT_DIR/01-python-syntax.txt" "python3 -m py_compile $(dirname "$0")/app/app.py"
# Remove any __pycache__ that may have been created
rm -rf $(dirname "$0")/app/__pycache__

# 02: Bash syntax check on all .sh scripts in this day folder
for script in $(find $(dirname "$0") -maxdepth 1 -type f -name "*.sh"); do
  log_output "$OUTPUT_DIR/02-bash-syntax-$(basename "$script" .sh).txt" "bash -n \"$script\""
done

# 03: shellcheck if available
if command -v shellcheck >/dev/null 2>&1; then
  for script in $(find $(dirname "$0") -maxdepth 1 -type f -name "*.sh"); do
    log_output "$OUTPUT_DIR/03-shellcheck-$(basename "$script" .sh).txt" "shellcheck \"$script\""
  done
else
  echo "hadolint not installed; skipped" > "$OUTPUT_DIR/03-shellcheck.txt"
fi

# 04: hadolint on Dockerfiles if available
if command -v hadolint >/dev/null 2>&1; then
  for df in $(find $(dirname "$0") -maxdepth 1 -type f -name "Dockerfile*" -not -name "Dockerfile.naive"); do
    log_output "$OUTPUT_DIR/04-hadolint-$(basename "$df").txt" "hadolint \"$df\""
  done
else
  echo "hadolint not installed; skipped" > "$OUTPUT_DIR/04-hadolint.txt"
fi

# 05: Simple textual review of Dockerfiles
review() {
  local df=$1
  local out=$2
  echo "# Instruction keywords in $df" > "$out"
  grep -E '^(FROM|RUN|COPY|ADD|USER|ENTRYPOINT|CMD|HEALTHCHECK|ENV|ARG|EXPOSE|LABEL|WORKDIR)' "$df" >> "$out"
  echo "\n# Checks" >> "$out"
  if grep -q 'ADD' "$df"; then echo "FAIL: ADD found" >> "$out"; else echo "PASS: no ADD" >> "$out"; fi
  if grep -q ':latest' "$df"; then echo "FAIL: floating tag :latest" >> "$out"; else echo "PASS: no :latest" >> "$out"; fi
  if grep -Eiq '(password|secret|token)' "$df"; then echo "FAIL: potential secret" >> "$out"; else echo "PASS: no secret strings" >> "$out"; fi
  if grep -q '^USER' "$df"; then echo "PASS: USER instruction present" >> "$out"; else echo "FAIL: missing USER" >> "$out"; fi
  if grep -q '^ENTRYPOINT\["' "$df"; then echo "PASS: exec-form ENTRYPOINT" >> "$out"; else echo "FAIL: missing exec-form ENTRYPOINT" >> "$out"; fi
  if grep -q '^HEALTHCHECK' "$df"; then echo "PASS: HEALTHCHECK present" >> "$out"; else echo "FAIL: missing HEALTHCHECK" >> "$out"; fi
}
review "$(dirname "$0")/Dockerfile" "$OUTPUT_DIR/05-dockerfile-review.txt"
review "$(dirname "$0")/Dockerfile.naive" "$OUTPUT_DIR/05-dockerfile-naive-review.txt"

# 06: .dockerignore sanity check
if grep -q '^\.git' "$(dirname "$0")/.dockerignore" && grep -q '^\.env' "$(dirname "$0")/.dockerignore" && grep -q '^venv' "$(dirname "$0")/.dockerignore"; then
  echo "PASS: .dockerignore contains required patterns" > "$OUTPUT_DIR/06-dockerignore.txt"
else
  echo "FAIL: .dockerignore missing some patterns" > "$OUTPUT_DIR/06-dockerignore.txt"
fi
