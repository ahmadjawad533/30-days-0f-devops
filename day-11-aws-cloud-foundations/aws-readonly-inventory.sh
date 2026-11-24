#!/usr/bin/env bash
set -u

# -------------------------------------------------------------------
# Day 11 – AWS read‑only inventory script (no resource creation)
# Safety: must be run with a non‑root credential and explicit region.
# -------------------------------------------------------------------

# Verify required environment variable
if [[ -z "${LAB11_REGION:-}" ]]; then
  echo "Error: LAB11_REGION environment variable is not set. Export it with the desired AWS region code (e.g., export LAB11_REGION=us-east-1) and re‑run the script."
  exit 1
fi

# Require explicit confirmation variable
if [[ "${LAB11_CONFIRM:-}" != "yes" ]]; then
  echo "Error: Set LAB11_CONFIRM=yes to confirm you understand this script is read‑only and will not create AWS resources."
  exit 1
fi

# Guard against running as root user
if [[ "$(id -u)" -eq 0 ]]; then
  echo "Error: Do not run this script as root. Use a non‑root user with appropriate AWS credentials."
  exit 1
fi

# Ensure AWS CLI is available (do not install)
if ! command -v aws >/dev/null 2>&1; then
  echo "AWS CLI not installed; see the official documentation at https://docs.aws.amazon.com/cli/"
  exit 1
fi

# Helper function to write redacted output
redact() {
  local label=$1
  local cmd=$2
  local outfile=$3
  local ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "# $label – $ts" > "$outfile"
  echo "$ $cmd" >> "$outfile"
  eval "$cmd" 2>/dev/null | \
    sed -E 's/[0-9]{12}/<redacted-account-id>/g' | \
    sed -E 's/(arn:aws:[^:]+:[^:]*:[0-9]{12}:[^\s]*)/<redacted-arn>/g' | \
    sed -E 's/(AKIA|ASIA)[A-Z0-9]{16}/<redacted-key>/g' >> "$outfile"
}

OUTPUT_DIR="$(dirname "$0")/../outputs"
mkdir -p "$OUTPUT_DIR"

# 01 – AWS CLI version
redact "CLI version" "aws --version" "$OUTPUT_DIR/01-cli-version.txt"

# 02 – Caller identity (root guard already performed)
# Capture only the caller type and account id, redacted
caller_info=$(aws sts get-caller-identity --query "{Arn:Arn,Account:Account}" --output text 2>/dev/null || true)
# Redact ARN and account id
redacted=$(echo "$caller_info" | sed -E 's/[0-9]{12}/<redacted-account-id>/g' | sed -E 's/(arn:aws:[^:]+:[^:]*:[0-9]{12}:[^\s]*)/<redacted-arn>/g')
printf "# Caller identity – %s\n# $ %s\n%s\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "aws sts get-caller-identity" "$redacted" > "$OUTPUT_DIR/02-caller-identity.txt"

# 03 – List all AWS regions (opt‑in status only)
redact "Regions list" "aws ec2 describe-regions --all-regions --query 'Regions[].{RegionName:RegionName,OptInStatus:OptInStatus}' --output table" "$OUTPUT_DIR/03-regions.txt"

# 04 – Availability zones for the selected region
redact "AZs for $LAB11_REGION" "aws ec2 describe-availability-zones --region \"$LAB11_REGION\" --all-availability-zones --query 'AvailabilityZones[].{ZoneName:ZoneName,ZoneId:ZoneId,State:State,ZoneType:ZoneType}' --output table" "$OUTPUT_DIR/04-azs.txt"

# 05 – Summary note
printf "# Summary – %s\nThe files above contain redacted AWS inventory data. No resources were created or modified.\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$OUTPUT_DIR/05-summary.txt"

exit 0
