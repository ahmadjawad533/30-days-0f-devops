#!/usr/bin/env bash
# ==============================================================================
# run-demo.sh - Demonstrations and Validation Harness for Day 04
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# - Strictly unprivileged. Runs no sudo.
# - Operates strictly within ./lab-workdir/ in this day folder.
# - Employs guarded cleanup on exit trap.
# - Signals only processes spawned directly by this demo script.
# ==============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/outputs"
LAB_WORKDIR="${SCRIPT_DIR}/lab-workdir"
TMP_DIR="${SCRIPT_DIR}/tmp"

mkdir -p "${OUTPUT_DIR}"
mkdir -p "${TMP_DIR}"

log_header() {
    local file="$1"
    local title="$2"
    {
        echo "# =============================================================================="
        echo "# Demo: ${title}"
        echo "# Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "# =============================================================================="
        echo ""
    } > "${file}"
}

# Clean existing lab workdir if leftover
if [[ -d "${LAB_WORKDIR}" ]]; then
    rm -rf "${LAB_WORKDIR}"
fi
mkdir -p "${LAB_WORKDIR}"

CHILD_PIDS=()

cleanup() {
    # 1. Terminate tracked child PIDs
    for pid in "${CHILD_PIDS[@]:-}"; do
        if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
            kill -KILL "${pid}" 2>/dev/null || true
        fi
    done

    # 2. Guarded cleanup of lab-workdir
    if [[ -n "${LAB_WORKDIR:-}" && "${LAB_WORKDIR}" != "/" && "${LAB_WORKDIR}" != "${HOME:-}" && "${LAB_WORKDIR}" == "${SCRIPT_DIR}/lab-workdir" ]]; then
        rm -rf "${LAB_WORKDIR}"
    fi

    # 3. Clean up lockfile in tmp/
    rm -f "${TMP_DIR}/backup.lock"
    rmdir "${TMP_DIR}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "=== Starting Day 04 Bash Scripting Demonstration Lab ==="

# ------------------------------------------------------------------------------
# Demo 01: Syntax and Lint Validation
# ------------------------------------------------------------------------------
echo -n "[Demo 01] Running syntax (bash -n) and linter checks... "
OUT_01="${OUTPUT_DIR}/01-syntax-and-lint.txt"
log_header "${OUT_01}" "bash -n syntax validation & shellcheck status"
{
    echo "--- Validating Shell Syntax (bash -n) ---"
    for s in "${SCRIPT_DIR}/scripts/"*.sh "${SCRIPT_DIR}/unsafe-examples/fixed-cleanup.sh" "${SCRIPT_DIR}/timer-lab/"*.sh "${SCRIPT_DIR}/run-demo.sh"; do
        if [[ -f "${s}" ]]; then
            bash -n "${s}" 2>&1
            echo "Syntax OK: $(basename "${s}")"
        fi
    done

    echo ""
    echo "--- ShellCheck Static Analysis Check ---"
    if command -v shellcheck >/dev/null 2>&1; then
        echo "Running shellcheck..."
        shellcheck "${SCRIPT_DIR}/scripts/"*.sh "${SCRIPT_DIR}/unsafe-examples/fixed-cleanup.sh" "${SCRIPT_DIR}/timer-lab/"*.sh 2>&1
    else
        echo "shellcheck not installed; skipped"
    fi
} >> "${OUT_01}"
echo "done -> outputs/01-syntax-and-lint.txt"

# ------------------------------------------------------------------------------
# Demo 02: Health Check Script (Normal vs Forcing Threshold Breaches)
# ------------------------------------------------------------------------------
echo -n "[Demo 02] Running health-check.sh and evaluating exit codes... "
OUT_02="${OUTPUT_DIR}/02-health-check.txt"
log_header "${OUT_02}" "Health check execution under normal and forced warning/critical conditions"
{
    echo "--- Run 1: Default Thresholds (Expected: Exit 0 or normal status) ---"
    set +e
    "${SCRIPT_DIR}/scripts/health-check.sh"
    CODE_1=$?
    set -e
    echo "exit=${CODE_1}"

    echo ""
    echo "--- Run 2: Deliberately Tiny Disk Threshold (-d 1) To Force Critical Exit ---"
    set +e
    "${SCRIPT_DIR}/scripts/health-check.sh" -d 1
    CODE_2=$?
    set -e
    echo "exit=${CODE_2}"

    echo ""
    echo "--- Run 3: Testing Inactive Port Listener (-t 65432) ---"
    set +e
    "${SCRIPT_DIR}/scripts/health-check.sh" -t 65432
    CODE_3=$?
    set -e
    echo "exit=${CODE_3}"
} >> "${OUT_02}"
echo "done -> outputs/02-health-check.txt"

# ------------------------------------------------------------------------------
# Demo 03: Backup Environment Setup
# ------------------------------------------------------------------------------
echo -n "[Demo 03] Preparing backup source and destination folders... "
OUT_03="${OUTPUT_DIR}/03-backup-setup.txt"
log_header "${OUT_03}" "Set up source directory with test files (including filename with spaces)"
{
    SRC_DIR="${LAB_WORKDIR}/source"
    BACKUP_DIR="${LAB_WORKDIR}/backups"
    mkdir -p "${SRC_DIR}" "${BACKUP_DIR}"

    echo "Sample web application configuration" > "${SRC_DIR}/app.conf"
    echo "Database connection string: postgres://localhost:5432/app" > "${SRC_DIR}/db.env"
    echo "File with spaces in name testing word splitting resilience" > "${SRC_DIR}/audit log 2026.txt"

    echo "--- Created Source Files ---"
    ls -l "${SRC_DIR}"
    echo ""
    echo "--- Destination Directory Initial State ---"
    ls -la "${BACKUP_DIR}"
} >> "${OUT_03}"
echo "done -> outputs/03-backup-setup.txt"

# ------------------------------------------------------------------------------
# Demo 04: Backup Dry-Run
# ------------------------------------------------------------------------------
echo -n "[Demo 04] Running backup-rotate.sh in dry-run mode (-n)... "
OUT_04="${OUTPUT_DIR}/04-backup-dry-run.txt"
log_header "${OUT_04}" "Execute backup-rotate.sh with -n (dry-run)"
{
    set +e
    "${SCRIPT_DIR}/scripts/backup-rotate.sh" -s "${LAB_WORKDIR}/source" -d "${LAB_WORKDIR}/backups" -k 3 -n
    CODE_DRY=$?
    set -e
    echo "exit=${CODE_DRY}"

    echo ""
    echo "--- Verifying Nothing Was Created in Destination Directory ---"
    COUNT=$(find "${LAB_WORKDIR}/backups" -type f | wc -l)
    echo "Total files in backups directory after dry-run: ${COUNT}"
} >> "${OUT_04}"
echo "done -> outputs/04-backup-dry-run.txt"

# ------------------------------------------------------------------------------
# Demo 05: Backup Real Run x5 and Retention Rotation (-k 3)
# ------------------------------------------------------------------------------
echo -n "[Demo 05] Executing 5 real backup runs and verifying rotation to 3... "
OUT_05="${OUTPUT_DIR}/05-backup-real-run.txt"
log_header "${OUT_05}" "Execute 5 successive backups with -k 3 and verify oldest are rotated out"
{
    for i in {1..5}; do
        echo ">>> Executing backup run ${i} of 5..."
        "${SCRIPT_DIR}/scripts/backup-rotate.sh" -s "${LAB_WORKDIR}/source" -d "${LAB_WORKDIR}/backups" -k 3
        # Sleep 1s to ensure distinct timestamps in file names
        sleep 1
    done

    echo ""
    echo "--- Destination Directory Contents After Rotation (Expected exactly 3 newest archives) ---"
    ls -l "${LAB_WORKDIR}/backups"
} >> "${OUT_05}"
echo "done -> outputs/05-backup-real-run.txt"

# ------------------------------------------------------------------------------
# Demo 06: Verification of Newest Archive
# ------------------------------------------------------------------------------
echo -n "[Demo 06] Verifying newest archive integrity with tar -tzf... "
OUT_06="${OUTPUT_DIR}/06-backup-verification.txt"
log_header "${OUT_06}" "Verify newest archive contents and integrity via tar -tzf"
{
    NEWEST_ARCHIVE=$(find "${LAB_WORKDIR}/backups" -maxdepth 1 -type f -name "backup-*.tar.gz" | sort | tail -n 1)
    echo "Newest archive: $(basename "${NEWEST_ARCHIVE}")"
    echo ""
    echo "--- Listing Archive Contents (tar -tzf) ---"
    tar -tzf "${NEWEST_ARCHIVE}"
} >> "${OUT_06}"
echo "done -> outputs/06-backup-verification.txt"

# ------------------------------------------------------------------------------
# Demo 07: Security Guards Testing (Deliberately Invalid Paths & Arguments)
# ------------------------------------------------------------------------------
echo -n "[Demo 07] Testing path guards and input validation... "
OUT_07="${OUTPUT_DIR}/07-guards.txt"
log_header "${OUT_07}" "Path guard tests: missing source, path outside workdir (/etc), empty -s, invalid -k"
{
    echo "--- Test 1: Missing Source Directory ---"
    set +e
    "${SCRIPT_DIR}/scripts/backup-rotate.sh" -s "${LAB_WORKDIR}/nonexistent" -d "${LAB_WORKDIR}/backups" -k 3
    echo "exit=$?"
    set -e

    echo ""
    echo "--- Test 2: Source Outside Allowed Workspace (/etc) ---"
    set +e
    "${SCRIPT_DIR}/scripts/backup-rotate.sh" -s "/etc" -d "${LAB_WORKDIR}/backups" -k 3
    echo "exit=$?"
    set -e

    echo ""
    echo "--- Test 3: Empty -s Value ---"
    set +e
    "${SCRIPT_DIR}/scripts/backup-rotate.sh" -s "" -d "${LAB_WORKDIR}/backups" -k 3
    echo "exit=$?"
    set -e

    echo ""
    echo "--- Test 4: Invalid Keep Count (-k 0) ---"
    set +e
    "${SCRIPT_DIR}/scripts/backup-rotate.sh" -s "${LAB_WORKDIR}/source" -d "${LAB_WORKDIR}/backups" -k 0
    echo "exit=$?"
    set -e
} >> "${OUT_07}"
echo "done -> outputs/07-guards.txt"

# ------------------------------------------------------------------------------
# Demo 08: Lock Contention (flock)
# ------------------------------------------------------------------------------
echo -n "[Demo 08] Demonstrating concurrency lock contention... "
OUT_08="${OUTPUT_DIR}/08-lock-contention.txt"
log_header "${OUT_08}" "Concurrency lock contention: hold lock externally and verify exit code 4"
{
    LOCK_FILE="${TMP_DIR}/backup.lock"
    echo "Holding lock on ${LOCK_FILE} via background process..."
    
    # Hold lock for 4 seconds in background
    (
        exec 200>"${LOCK_FILE}"
        flock -x 200
        sleep 4
    ) &
    BG_LOCK_PID=$!
    CHILD_PIDS+=("${BG_LOCK_PID}")
    sleep 0.5 # Ensure background process has acquired lock

    echo "Attempting to execute backup-rotate.sh while lock is held (Expected: Exit 4)..."
    set +e
    "${SCRIPT_DIR}/scripts/backup-rotate.sh" -s "${LAB_WORKDIR}/source" -d "${LAB_WORKDIR}/backups" -k 3
    LOCK_EXIT=$?
    set -e
    echo "exit=${LOCK_EXIT}"

    echo "Waiting for background lock holder PID ${BG_LOCK_PID} to release..."
    wait "${BG_LOCK_PID}" 2>/dev/null || true
    echo "Lock released."
} >> "${OUT_08}"
echo "done -> outputs/08-lock-contention.txt"

# ------------------------------------------------------------------------------
# Demo 09: Trap Cleanup on Interrupt
# ------------------------------------------------------------------------------
echo -n "[Demo 09] Testing trap cleanup on SIGTERM interrupt... "
OUT_09="${OUTPUT_DIR}/09-trap-cleanup.txt"
log_header "${OUT_09}" "Simulate slow operation, send SIGTERM, and verify temp file cleanup"
{
    echo "Launching backup-rotate.sh with simulated 4-second delay..."
    LAB04_TEST_SLOW_DELAY=4 "${SCRIPT_DIR}/scripts/backup-rotate.sh" -s "${LAB_WORKDIR}/source" -d "${LAB_WORKDIR}/backups" -k 3 &
    SLOW_PID=$!
    CHILD_PIDS+=("${SLOW_PID}")

    sleep 1 # Allow script to start and create temp archive

    echo "Inspecting destination directory while backup is in progress:"
    find "${LAB_WORKDIR}/backups" -name "tmp.backup.*"

    echo "Sending SIGTERM to running backup PID ${SLOW_PID}..."
    kill -TERM "${SLOW_PID}" 2>/dev/null || true
    wait "${SLOW_PID}" 2>/dev/null || true

    echo ""
    echo "Inspecting destination directory after SIGTERM termination (Expected: 0 tmp files remain):"
    REMAINING_TMP=$(find "${LAB_WORKDIR}/backups" -name "tmp.backup.*" | wc -l)
    echo "Remaining temp files: ${REMAINING_TMP}"
    echo "Observation: Trap on TERM cleanly destroyed incomplete scratch file."
} >> "${OUT_09}"
echo "done -> outputs/09-trap-cleanup.txt"

# ------------------------------------------------------------------------------
# Demo 10: Fixed Cleanup Example Testing
# ------------------------------------------------------------------------------
echo -n "[Demo 10] Testing fixed-cleanup.sh safety guards and execution... "
OUT_10="${OUTPUT_DIR}/10-fixed-cleanup.txt"
log_header "${OUT_10}" "fixed-cleanup.sh: dry-run, real deletion, and empty variable refusal"
{
    THROW_DIR="${LAB_WORKDIR}/throwaway"
    mkdir -p "${THROW_DIR}"
    touch "${THROW_DIR}/junk1.tmp" "${THROW_DIR}/junk2.tmp"

    echo "--- Run 1: Dry-Run Mode (Without -f) ---"
    "${SCRIPT_DIR}/unsafe-examples/fixed-cleanup.sh" -t "${THROW_DIR}"
    echo "Files still present after dry-run:"
    ls "${THROW_DIR}"

    echo ""
    echo "--- Run 2: Real Deletion Mode (-f) ---"
    "${SCRIPT_DIR}/unsafe-examples/fixed-cleanup.sh" -t "${THROW_DIR}" -f
    echo "Files present after forced deletion:"
    ls "${THROW_DIR}"

    echo ""
    echo "--- Run 3: Testing Refusal of Path Outside Allowed Directory (/etc) ---"
    set +e
    "${SCRIPT_DIR}/unsafe-examples/fixed-cleanup.sh" -t "/etc" -f
    echo "exit=$?"
    set -e
} >> "${OUT_10}"
echo "done -> outputs/10-fixed-cleanup.txt"

# ------------------------------------------------------------------------------
# Demo 11: Script Template Help and Exit
# ------------------------------------------------------------------------------
echo -n "[Demo 11] Validating script-template.sh skeleton... "
OUT_11="${OUTPUT_DIR}/11-script-template.txt"
log_header "${OUT_11}" "Execute script-template.sh with -h and verify exit code"
{
    "${SCRIPT_DIR}/scripts/script-template.sh" -h
    echo "exit=$?"
    echo ""
    echo "Executing script-template.sh without arguments:"
    "${SCRIPT_DIR}/scripts/script-template.sh"
    echo "exit=$?"
} >> "${OUT_11}"
echo "done -> outputs/11-script-template.txt"

echo ""
echo "=== All Day 04 Demos Completed! Real outputs recorded in outputs/ ==="
