#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="${LAB_DIR}/lab-workdir"
OUTPUTS="${LAB_DIR}/outputs"

mkdir -p "$WORKDIR/logs" "$OUTPUTS"

# Generate synthetic logs
"${LAB_DIR}/generate-synthetic-logs.sh"

# Run inspection script (creates output files)
"${LAB_DIR}/inspect-logging.sh"

# Prepare logrotate config with actual log directory
CONF_TMP="${WORKDIR}/lab05-app.conf"
sed "s|@LABDIR@|${WORKDIR}/logs|g" "${LAB_DIR}/logrotate-lab/lab05-app.conf" > "$CONF_TMP"

# Dry‑run logrotate to see actions
logrotate -d -s "${WORKDIR}/logrotate.status" "$CONF_TMP" || true

# Perform real rotation
logrotate "$CONF_TMP"

# Capture logrotate status if generated
if [ -f "${WORKDIR}/logrotate.status" ]; then
  cp "${WORKDIR}/logrotate.status" "${OUTPUTS}/logrotate-status.txt"
fi

# Clean up synthetic logs (keep outputs)
rm -rf "$WORKDIR"

echo "Lab completed. All output files are in $OUTPUTS"
