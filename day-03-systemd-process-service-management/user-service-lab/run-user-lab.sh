#!/usr/bin/env bash
# ==============================================================================
# run-user-lab.sh - Hands-on systemd User Service Laboratory
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# Operates strictly within unprivileged user space (~/.config/systemd/user).
# Never uses sudo. Never touches any unit that does not start with "lab03-".
# Must be run manually by the author/student, NEVER by automated agents.
# ==============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/../outputs"
USER_UNIT_DIR="${HOME}/.config/systemd/user"

# 1. Refuse to run as root
if [[ "${EUID}" -eq 0 ]]; then
    echo "Error: Do not run this script as root! User services must run under a regular user account." >&2
    exit 1
fi

# 2. Require confirmation environment variable
if [[ "${CONFIRM_RUN_LAB03:-}" != "true" ]]; then
    echo "Safety safeguard: CONFIRM_RUN_LAB03=true is not set."
    echo "To run this user-service lab manually, execute:"
    echo "  export CONFIRM_RUN_LAB03=true"
    echo "  $0"
    exit 1
fi

# 3. Interactive confirmation prompt
echo "NOTICE: This script installs and manages user services ('lab03-heartbeat' and 'lab03-broken')"
echo "under your personal user systemd directory: ${USER_UNIT_DIR}"
read -r -p "Are you sure you want to proceed? Type 'yes' to continue: " RESPONSE
if [[ "${RESPONSE}" != "yes" ]]; then
    echo "Aborted by user."
    exit 0
fi

# Prepare directories
mkdir -p "${USER_UNIT_DIR}"
mkdir -p "${OUTPUT_DIR}"

log_header() {
    local file="$1"
    local title="$2"
    {
        echo "# =============================================================================="
        echo "# Lab Step: ${title}"
        echo "# Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "# =============================================================================="
        echo ""
    } > "${file}"
}

echo "=== Running User Service Lab ==="

# ------------------------------------------------------------------------------
# Step 1: Install and Start lab03-heartbeat.service
# ------------------------------------------------------------------------------
echo -n "[Step 1] Installing and starting lab03-heartbeat.service... "
OUT_U1="${OUTPUT_DIR}/userlab-01-start-heartbeat.txt"
log_header "${OUT_U1}" "Install and start lab03-heartbeat.service"
{
    cp "${SCRIPT_DIR}/lab03-heartbeat.service" "${USER_UNIT_DIR}/lab03-heartbeat.service"
    systemctl --user daemon-reload
    systemctl --user start lab03-heartbeat.service

    echo "--- systemctl --user status lab03-heartbeat.service ---"
    systemctl --user status lab03-heartbeat.service --no-pager 2>&1 || true

    echo ""
    echo "--- Selected Low-Level Unit Properties ---"
    systemctl --user show lab03-heartbeat.service -p MainPID,ControlGroup,ActiveState,SubState,NRestarts,Restart --no-pager 2>&1
} >> "${OUT_U1}"
echo "done -> outputs/userlab-01-start-heartbeat.txt"

# ------------------------------------------------------------------------------
# Step 2: Journalctl Logs and Auto-Restart on Kill
# ------------------------------------------------------------------------------
echo -n "[Step 2] Capturing logs and testing auto-restart upon SIGKILL... "
OUT_U2="${OUTPUT_DIR}/userlab-02-restart-on-failure.txt"
log_header "${OUT_U2}" "Verify journal logs and test Restart=on-failure with systemctl --user kill"
{
    sleep 6 # Allow heartbeat service to emit at least one log entry

    echo "--- Recent Journal Logs (journalctl --user -u lab03-heartbeat.service -n 15) ---"
    journalctl --user -u lab03-heartbeat.service -n 15 --no-pager 2>&1

    INITIAL_PID=$(systemctl --user show lab03-heartbeat.service -p MainPID --value)
    echo ""
    echo "Initial MainPID: ${INITIAL_PID}"
    echo "Killing service main process with SIGKILL (simulating unhandled crash)..."
    systemctl --user kill -s KILL lab03-heartbeat.service

    # Wait for systemd RestartSec=2 delay to trigger recovery
    sleep 4

    echo ""
    echo "--- Post-Kill Unit Properties (Showing New MainPID & NRestarts increment) ---"
    systemctl --user show lab03-heartbeat.service -p MainPID,ControlGroup,ActiveState,SubState,NRestarts,Restart --no-pager 2>&1
} >> "${OUT_U2}"
echo "done -> outputs/userlab-02-restart-on-failure.txt"

# ------------------------------------------------------------------------------
# Step 3: Apply Drop-In Override
# ------------------------------------------------------------------------------
echo -n "[Step 3] Applying drop-in configuration override... "
OUT_U3="${OUTPUT_DIR}/userlab-03-drop-in-override.txt"
log_header "${OUT_U3}" "Install drop-in override and view combined unit definition"
{
    DROPIN_DIR="${USER_UNIT_DIR}/lab03-heartbeat.service.d"
    mkdir -p "${DROPIN_DIR}"
    cp "${SCRIPT_DIR}/override.conf.example" "${DROPIN_DIR}/override.conf"

    systemctl --user daemon-reload
    systemctl --user restart lab03-heartbeat.service

    echo "--- Combined Unit Definition (systemctl --user cat lab03-heartbeat.service) ---"
    systemctl --user cat lab03-heartbeat.service --no-pager 2>&1

    echo ""
    echo "--- Verifying Updated Properties (RestartSec=5) ---"
    systemctl --user show lab03-heartbeat.service -p RestartUSec,Environment --no-pager 2>&1
} >> "${OUT_U3}"
echo "done -> outputs/userlab-03-drop-in-override.txt"

# ------------------------------------------------------------------------------
# Step 4: Install Broken Service and Observe 203/EXEC Failure Code
# ------------------------------------------------------------------------------
echo -n "[Step 4] Testing lab03-broken.service and capturing exit failure code... "
OUT_U4="${OUTPUT_DIR}/userlab-04-broken-service.txt"
log_header "${OUT_U4}" "Start broken service and capture failure status (203/EXEC)"
{
    cp "${SCRIPT_DIR}/lab03-broken.service" "${USER_UNIT_DIR}/lab03-broken.service"
    systemctl --user daemon-reload
    systemctl --user start lab03-broken.service 2>&1 || true

    sleep 1

    echo "--- Status of Broken Unit (systemctl --user status lab03-broken.service) ---"
    systemctl --user status lab03-broken.service --no-pager 2>&1 || true

    echo ""
    echo "--- Exit Code Inspection (ExecMainStatus and Result) ---"
    systemctl --user show lab03-broken.service -p ActiveState,SubState,Result,ExecMainStatus --no-pager 2>&1
    echo "Note: ExecMainStatus=203 corresponds to EXIT_EXEC (systemd failed to execute binary; path missing or non-executable)."
} >> "${OUT_U4}"
echo "done -> outputs/userlab-04-broken-service.txt"

# ------------------------------------------------------------------------------
# Step 5: Teardown Lab Units Cleanly
# ------------------------------------------------------------------------------
echo -n "[Step 5] Cleaning up user services... "
"${SCRIPT_DIR}/cleanup-user-lab.sh" --auto
echo "done"

echo ""
echo "=== User Service Lab Complete! All lab outputs saved in outputs/ ==="
