#!/usr/bin/env bash
set -u

# Directory paths
BASE_DIR=$(dirname "$(realpath "$0")")
OUTPUT_DIR="$BASE_DIR/../outputs"
mkdir -p "$OUTPUT_DIR"

timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# 01 – Bash syntax check for all .sh files in this day folder
find "$BASE_DIR" -type f -name "*.sh" -print0 | while IFS= read -r -d '' file; do
  bash -n "$file" > "$OUTPUT_DIR/01-bash-n-$(basename "$file").txt" 2>&1 || true
done

# 02 – Shellcheck if available (record findings)
if command -v shellcheck >/dev/null 2>&1; then
  find "$BASE_DIR" -type f -name "*.sh" -exec shellcheck {} + > "$OUTPUT_DIR/02-shellcheck.txt" 2>&1 || true
else
  echo "Shellcheck not installed – skipping" > "$OUTPUT_DIR/02-shellcheck.txt"
fi

# 03 – Audit aws-readonly-inventory.sh for forbidden patterns

grep -En "aws configure|aws iam|aws s3|aws organizations|aws ce|create-|delete-|put-|modify-|run-instances|terminate-" "$BASE_DIR/aws-readonly-inventory.sh" > "$OUTPUT_DIR/03-audit.txt" || true
# Ensure required guards are present
grep -q "LAB11_REGION" "$BASE_DIR/aws-readonly-inventory.sh" || echo "Missing LAB11_REGION check" >> "$OUTPUT_DIR/03-audit.txt"
grep -q "LAB11_CONFIRM" "$BASE_DIR/aws-readonly-inventory.sh" || echo "Missing LAB11_CONFIRM check" >> "$OUTPUT_DIR/03-audit.txt"
grep -q "id -u" "$BASE_DIR/aws-readonly-inventory.sh" || echo "Missing root guard" >> "$OUTPUT_DIR/03-audit.txt"

# 04 – Secret scan for keys, 12‑digit numbers, base64 strings near "secret" or "key"
grep -R -nE "AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}" "$BASE_DIR" > "$OUTPUT_DIR/04-secret-scan.txt" 2>/dev/null || true
grep -R -nE "[0-9]{12}" "$BASE_DIR" >> "$OUTPUT_DIR/04-secret-scan.txt" 2>/dev/null || true
grep -R -nE "(secret|key)[^\"\s]{0,20}[A-Za-z0-9+/]{32,}" "$BASE_DIR" >> "$OUTPUT_DIR/04-secret-scan.txt" 2>/dev/null || true

# 05 – External links audit (allowed list defined below)
ALLOWED=(
  "https://aws.amazon.com/about-aws/global-infrastructure/"
  "https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-regions.html"
  "https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html"
  "https://docs.aws.amazon.com/ram/latest/userguide/working-with-az-ids.html"
  "https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/"
  "https://aws.amazon.com/compliance/shared-responsibility-model/"
  "https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html"
  "https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html"
  "https://aws.amazon.com/free/"
  "https://docs.aws.amazon.com/cli/"
)

grep -RhoE "https?://[^\"\s]+" "$BASE_DIR" | sort -u > "$OUTPUT_DIR/05-links.txt"
printf "%s\n" "${ALLOWED[@]}" > "$OUTPUT_DIR/allowed.tmp"
grep -Fxv -f "$OUTPUT_DIR/allowed.tmp" "$OUTPUT_DIR/05-links.txt" > "$OUTPUT_DIR/05-unallowed-links.txt" || true
rm -f "$OUTPUT_DIR/allowed.tmp"

# 06 – Documentation audit for numeric counts, dollar amounts, free‑tier wording

grep -RinE "[0-9]+[[:space:]]+Regions?|[0-9]+[[:space:]]+Availability[[:space:]]+Zones?|\$[0-9]+|Free[[:space:]]+Tier" "$BASE_DIR" > "$OUTPUT_DIR/06-doc-audit.txt" 2>/dev/null || true

# 07 – Note about inventory script not executed
printf "# %s\nThe AWS inventory script was not executed by the agent; it will be run by the author with a non‑root credential.\n" "$(timestamp)" > "$OUTPUT_DIR/07-note.txt"

exit 0
