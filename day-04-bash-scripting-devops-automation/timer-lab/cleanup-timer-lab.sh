#!/usr/bin/env bash
# ==============================================================================
# cleanup-timer-lab.sh - Teardown for Day 04 User Timer Lab
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# Operates strictly within ~/.config/systemd/user.
# Strictly guarded to touch ONLY files and directories prefixed with "lab04-".
# ==============================================================================

set -u

USER_UNIT_DIR="${HOME}/.config/systemd/user"
AUTO_MODE="${1:-}"

if [[ "${AUTO_MODE}" != "--auto" ]]; then
    echo "WARNING: This will stop, disable, and delete all 'lab04-' user units from: ${USER_UNIT_DIR}"
    read -r -p "Are you sure you want to proceed? Type 'yes' to continue: " CONFIRM
    if [[ "${CONFIRM}" != "yes" ]]; then
        echo "Cleanup aborted."
        exit 0
    fi
fi

# 1. Stop and disable timer and service
if systemctl --user is-active lab04-backup.timer >/dev/null 2>&1; then
    echo "Stopping lab04-backup.timer..."
    systemctl --user stop lab04-backup.timer 2>/dev/null || true
fi
systemctl --user disable lab04-backup.timer 2>/dev/null || true

if systemctl --user is-active lab04-backup.service >/dev/null 2>&1; then
    systemctl --user stop lab04-backup.service 2>/dev/null || true
fi
systemctl --user reset-failed lab04-backup.service lab04-backup.timer 2>/dev/null || true

# 2. Guarded deletion of unit files
if [[ -f "${USER_UNIT_DIR}/lab04-backup.timer" ]]; then
    rm -f "${USER_UNIT_DIR}/lab04-backup.timer"
fi

if [[ -f "${USER_UNIT_DIR}/lab04-backup.service" ]]; then
    rm -f "${USER_UNIT_DIR}/lab04-backup.service"
fi

# 3. Reload user daemon
systemctl --user daemon-reload

echo "=== Day 04 User Timer Cleanup Complete ==="
