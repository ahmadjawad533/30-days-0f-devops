#!/usr/bin/env bash
# ==============================================================================
# run-timer-lab.sh - Hands-On systemd User Timer Laboratory
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# Operates strictly within unprivileged user space (~/.config/systemd/user).
# Never uses sudo. Never touches any unit that does not start with "lab04-".
# Must be run manually by the author/student, NEVER by automated agents.
# ==============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DAY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${REPO_DAY_DIR}/outputs"
USER_UNIT_DIR="${HOME}/.config/systemd/user"

# 1. Refuse to run as root
if [[ "${EUID}" -eq 0 ]]; then
    echo "Error: Do not run this script as root! User timers must run under a regular user account." >&2
    exit 1
fi

# 2. Require confirmation environment variable
if [[ "${CONFIRM_RUN_LAB04:-}" != "true" ]]; then
    echo "Safety safeguard: CONFIRM_RUN_LAB04=true is not set."
    echo "To run this user-timer lab manually, execute:"
    echo "  export CONFIRM_RUN_LAB04=true"
    echo "  $0"
    exit 1
fi

# 3. Interactive confirmation prompt
echo "NOTICE: This script installs and activates a systemd user timer ('lab04-backup.timer')"
echo "under your personal user systemd directory: ${USER_UNIT_DIR}"
read -r -p "Are you sure you want to proceed? Type 'yes' to continue: " RESPONSE
if [[ "${RESPONSE}" != "yes" ]]; then
    echo "Aborted by user."
    exit 0
fi

# Prepare directories
mkdir -p "${USER_UNIT_DIR}"
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${REPO_DAY_DIR}/lab-workdir/source"
mkdir -p "${REPO_DAY_DIR}/lab-workdir/backups"

# Populate sample data for backup
echo "Sample production configuration" > "${REPO_DAY_DIR}/lab-workdir/source/config.env"
echo "Important application log" > "${REPO_DAY_DIR}/lab-workdir/source/app.log"

log_header() {
    local file="$1"
    local title="$2"
    {
        echo "# =============================================================================="
        echo "# Timer Lab Step: ${title}"
        echo "# Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "# =============================================================================="
        echo ""
    } > "${file}"
}

echo "=== Running User Timer Lab ==="

# ------------------------------------------------------------------------------
# Step 1: Install and Substitute Repository Paths in Units
# ------------------------------------------------------------------------------
echo -n "[Step 1] Installing user unit and timer files... "
OUT_T1="${OUTPUT_DIR}/timerlab-01-install-timer.txt"
log_header "${OUT_T1}" "Substitute @REPO_DIR@ and install lab04 unit files"
{
    sed "s|@REPO_DIR@|${REPO_DAY_DIR}|g" "${SCRIPT_DIR}/lab04-backup.service" > "${USER_UNIT_DIR}/lab04-backup.service"
    cp "${SCRIPT_DIR}/lab04-backup.timer" "${USER_UNIT_DIR}/lab04-backup.timer"

    systemctl --user daemon-reload
    systemctl --user enable --now lab04-backup.timer

    echo "--- systemctl --user list-timers --no-pager ---"
    systemctl --user list-timers --no-pager | grep -E "NEXT|lab04" || true
} >> "${OUT_T1}"
echo "done -> outputs/timerlab-01-install-timer.txt"

# ------------------------------------------------------------------------------
# Step 2: Trigger Service Manually Once & Inspect Logs
# ------------------------------------------------------------------------------
echo -n "[Step 2] Triggering oneshot backup and capturing journal... "
OUT_T2="${OUTPUT_DIR}/timerlab-02-run-service.txt"
log_header "${OUT_T2}" "Trigger backup oneshot service and inspect journalctl logs"
{
    systemctl --user start lab04-backup.service

    echo "--- systemctl --user status lab04-backup.service ---"
    systemctl --user status lab04-backup.service --no-pager 2>&1 || true

    echo ""
    echo "--- Journal Output (journalctl --user -u lab04-backup.service -n 15) ---"
    journalctl --user -u lab04-backup.service -n 15 --no-pager 2>&1
} >> "${OUT_T2}"
echo "done -> outputs/timerlab-02-run-service.txt"

# ------------------------------------------------------------------------------
# Step 3: Cleanup
# ------------------------------------------------------------------------------
echo -n "[Step 3] Cleaning up user units... "
"${SCRIPT_DIR}/cleanup-timer-lab.sh" --auto
echo "done"

echo ""
echo "=== Timer Lab Complete! Outputs recorded in outputs/ ==="
