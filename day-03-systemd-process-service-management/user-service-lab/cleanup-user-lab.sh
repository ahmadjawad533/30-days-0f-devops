#!/usr/bin/env bash
# ==============================================================================
# cleanup-user-lab.sh - Teardown for Day 03 User Service Lab
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# Operates strictly within ~/.config/systemd/user.
# Strictly guarded to touch ONLY files and directories prefixed with "lab03-".
# ==============================================================================

set -u

USER_UNIT_DIR="${HOME}/.config/systemd/user"
AUTO_MODE="${1:-}"

if [[ "${AUTO_MODE}" != "--auto" ]]; then
    echo "WARNING: This will stop, disable, and delete all 'lab03-' user units from: ${USER_UNIT_DIR}"
    read -r -p "Are you sure you want to proceed? Type 'yes' to continue: " CONFIRM
    if [[ "${CONFIRM}" != "yes" ]]; then
        echo "Cleanup aborted."
        exit 0
    fi
fi

# 1. Stop and disable lab units
for unit in lab03-heartbeat.service lab03-broken.service; do
    if systemctl --user is-active "${unit}" >/dev/null 2>&1 || systemctl --user is-failed "${unit}" >/dev/null 2>&1; then
        echo "Stopping ${unit}..."
        systemctl --user stop "${unit}" 2>/dev/null || true
    fi
    systemctl --user reset-failed "${unit}" 2>/dev/null || true
done

# 2. Guarded file and directory deletion
if [[ -f "${USER_UNIT_DIR}/lab03-heartbeat.service" ]]; then
    rm -f "${USER_UNIT_DIR}/lab03-heartbeat.service"
fi

if [[ -f "${USER_UNIT_DIR}/lab03-broken.service" ]]; then
    rm -f "${USER_UNIT_DIR}/lab03-broken.service"
fi

if [[ -d "${USER_UNIT_DIR}/lab03-heartbeat.service.d" ]]; then
    rm -rf "${USER_UNIT_DIR}/lab03-heartbeat.service.d"
fi

# 3. Reload user daemon to flush memory
systemctl --user daemon-reload

echo "=== Day 03 User Service Cleanup Complete ==="
