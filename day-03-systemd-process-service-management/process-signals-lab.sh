#!/usr/bin/env bash
# ==============================================================================
# process-signals-lab.sh - Process Signals, Priority, and States Laboratory
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# Strictly PROJECT-LOCAL and unprivileged. No sudo used.
# All operations track and signal ONLY child PIDs spawned directly by this script.
# Never uses pkill, killall, or kill by name.
# ==============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/outputs"
LAB_WORKDIR="${SCRIPT_DIR}/lab-workdir"

mkdir -p "${OUTPUT_DIR}"

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

# Track all child PIDs spawned by this script
CHILD_PIDS=()

cleanup_lab() {
    # 1. Terminate any tracked child processes still running
    for pid in "${CHILD_PIDS[@]:-}"; do
        if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
            kill -KILL "${pid}" 2>/dev/null || true
        fi
    done

    # 2. Guarded removal of lab-workdir
    if [[ -n "${LAB_WORKDIR:-}" && "${LAB_WORKDIR}" != "/" && "${LAB_WORKDIR}" != "${HOME:-}" && "${LAB_WORKDIR}" == "${SCRIPT_DIR}/lab-workdir" ]]; then
        rm -rf "${LAB_WORKDIR}"
    fi
}
trap cleanup_lab EXIT

echo "=== Starting Process Signals and Priority Lab (Unprivileged) ==="

# ------------------------------------------------------------------------------
# Demo A: Start Background Process and Inspect Attributes
# ------------------------------------------------------------------------------
echo -n "[Demo A] Starting background process and inspecting attributes... "
OUT_A="${OUTPUT_DIR}/demo-a-bg-process.txt"
log_header "${OUT_A}" "Start background process and inspect PID/attributes"
{
    sleep 300 &
    PID_A=$!
    CHILD_PIDS+=("${PID_A}")

    echo "Spawned child PID: ${PID_A}"
    echo "--- Process Status (ps -o pid,ppid,stat,ni,comm) ---"
    if kill -0 "${PID_A}" 2>/dev/null; then
        ps -o pid,ppid,stat,ni,comm -p "${PID_A}"
    else
        echo "Process ${PID_A} exited unexpectedly"
    fi
} >> "${OUT_A}"
echo "done -> outputs/demo-a-bg-process.txt"

# ------------------------------------------------------------------------------
# Demo B: Send SIGTERM and Observe Graceful Termination Exit Code
# ------------------------------------------------------------------------------
echo -n "[Demo B] Sending SIGTERM and capturing exit status... "
OUT_B="${OUTPUT_DIR}/demo-b-sigterm.txt"
log_header "${OUT_B}" "Send SIGTERM (Signal 15) and record exit status"
{
    echo "Target process PID: ${PID_A}"
    if kill -0 "${PID_A}" 2>/dev/null; then
        echo "Sending SIGTERM (kill -TERM ${PID_A})..."
        kill -TERM "${PID_A}"
        
        # Wait for the process to exit and capture exact exit status
        set +e
        wait "${PID_A}" 2>/dev/null
        EXIT_CODE_B=$?
        set -e

        echo "Process ${PID_A} terminated."
        echo "Exit status: ${EXIT_CODE_B}"
        echo "Explanation: 128 + 15 (SIGTERM) = 143. Standard POSIX exit code for signal termination."
    else
        echo "Target process ${PID_A} was not running"
    fi
} >> "${OUT_B}"
echo "done -> outputs/demo-b-sigterm.txt"

# ------------------------------------------------------------------------------
# Demo C: Send SIGKILL and Observe Immediate Termination Exit Code
# ------------------------------------------------------------------------------
echo -n "[Demo C] Sending SIGKILL and capturing exit status... "
OUT_C="${OUTPUT_DIR}/demo-c-sigkill.txt"
log_header "${OUT_C}" "Send SIGKILL (Signal 9) and record exit status"
{
    sleep 300 &
    PID_C=$!
    CHILD_PIDS+=("${PID_C}")

    echo "Spawned child PID: ${PID_C}"
    if kill -0 "${PID_C}" 2>/dev/null; then
        echo "Sending SIGKILL (kill -KILL ${PID_C})..."
        kill -KILL "${PID_C}"

        set +e
        wait "${PID_C}" 2>/dev/null
        EXIT_CODE_C=$?
        set -e

        echo "Process ${PID_C} terminated."
        echo "Exit status: ${EXIT_CODE_C}"
        echo "Explanation: 128 + 9 (SIGKILL) = 137. Uncatchable kernel-level process termination."
    else
        echo "Target process ${PID_C} was not running"
    fi
} >> "${OUT_C}"
echo "done -> outputs/demo-c-sigkill.txt"

# ------------------------------------------------------------------------------
# Demo D: Signal Trapping (SIGTERM vs SIGKILL)
# ------------------------------------------------------------------------------
echo -n "[Demo D] Testing signal trapping (SIGTERM catchable vs SIGKILL uncatchable)... "
OUT_D="${OUTPUT_DIR}/demo-d-signal-traps.txt"
log_header "${OUT_D}" "Signal Trapping: Catching SIGTERM vs uncatchable SIGKILL"
{
    echo "--- Case 1: Child with trap on SIGTERM ---"
    bash -c 'trap "echo caught SIGTERM; exit 0" TERM; while true; do sleep 1; done' &
    PID_D1=$!
    CHILD_PIDS+=("${PID_D1}")
    sleep 0.2

    echo "Sending SIGTERM to PID ${PID_D1}..."
    kill -TERM "${PID_D1}"
    set +e
    wait "${PID_D1}" 2>/dev/null
    EXIT_CODE_D1=$?
    set -e
    echo "Child ${PID_D1} handled SIGTERM cleanly. Exit code: ${EXIT_CODE_D1}"

    echo ""
    echo "--- Case 2: Child with trap on SIGTERM, receiving SIGKILL ---"
    bash -c 'trap "echo caught SIGTERM; exit 0" TERM; while true; do sleep 1; done' &
    PID_D2=$!
    CHILD_PIDS+=("${PID_D2}")
    sleep 0.2

    echo "Sending SIGKILL to PID ${PID_D2}..."
    kill -KILL "${PID_D2}"
    set +e
    wait "${PID_D2}" 2>/dev/null
    EXIT_CODE_D2=$?
    set -e
    echo "Child ${PID_D2} terminated by SIGKILL (trap had no effect). Exit code: ${EXIT_CODE_D2}"
} >> "${OUT_D}"
echo "done -> outputs/demo-d-signal-traps.txt"

# ------------------------------------------------------------------------------
# Demo E: SIGSTOP and SIGCONT Process Pausing
# ------------------------------------------------------------------------------
echo -n "[Demo E] Demonstrating process suspension (SIGSTOP) and resumption (SIGCONT)... "
OUT_E="${OUTPUT_DIR}/demo-e-sigstop-sigcont.txt"
log_header "${OUT_E}" "Process job suspension with SIGSTOP (T) and resumption with SIGCONT (S)"
{
    sleep 300 &
    PID_E=$!
    CHILD_PIDS+=("${PID_E}")

    echo "--- Initial Running State ---"
    ps -o pid,stat,comm -p "${PID_E}"

    echo ""
    echo "--- Sending SIGSTOP (kill -STOP ${PID_E}) ---"
    kill -STOP "${PID_E}"
    sleep 0.2
    ps -o pid,stat,comm -p "${PID_E}"
    echo "Note: Stat contains 'T' (stopped by job control signal)."

    echo ""
    echo "--- Sending SIGCONT (kill -CONT ${PID_E}) ---"
    kill -CONT "${PID_E}"
    sleep 0.2
    ps -o pid,stat,comm -p "${PID_E}"
    echo "Note: Stat returned to 'S' (interruptible sleep)."

    kill -KILL "${PID_E}" 2>/dev/null || true
} >> "${OUT_E}"
echo "done -> outputs/demo-e-sigstop-sigcont.txt"

# ------------------------------------------------------------------------------
# Demo F: Process Niceness and Priority Adjustment (renice)
# ------------------------------------------------------------------------------
echo -n "[Demo F] Testing process niceness adjustment with renice... "
OUT_F="${OUTPUT_DIR}/demo-f-renice.txt"
log_header "${OUT_F}" "Process Niceness and Priority adjustment (renice)"
{
    nice -n 5 sleep 300 &
    PID_F=$!
    CHILD_PIDS+=("${PID_F}")

    echo "--- Initial Priority with nice -n 5 ---"
    ps -o pid,ni,pri,stat,comm -p "${PID_F}"

    echo ""
    echo "--- Raising Niceness to 10 with renice (Unprivileged) ---"
    renice -n 10 -p "${PID_F}" 2>&1
    ps -o pid,ni,pri,stat,comm -p "${PID_F}"
    echo "Note: Raising niceness (lowering CPU priority) requires no root privileges."

    kill -KILL "${PID_F}" 2>/dev/null || true
} >> "${OUT_F}"
echo "done -> outputs/demo-f-renice.txt"

# ------------------------------------------------------------------------------
# Demo G: Optional Zombie Process Demonstration
# ------------------------------------------------------------------------------
echo -n "[Demo G] Testing Zombie process lifecycle (State Z)... "
OUT_G="${OUTPUT_DIR}/demo-g-zombie.txt"
log_header "${OUT_G}" "Zombie process lifecycle: child exits, parent delays wait()"
{
    if command -v python3 >/dev/null 2>&1; then
        ZOMBIE_SCRIPT="${LAB_WORKDIR}/zombie_demo.py"
        cat << 'PYEOF' > "${ZOMBIE_SCRIPT}"
import os
import time
import sys

pid = os.fork()
if pid == 0:
    # Child exits immediately
    sys.exit(0)
else:
    # Parent prints child PID and sleeps without calling wait()
    print(f"PARENT_PID={os.getpid()}")
    print(f"CHILD_PID={pid}", flush=True)
    time.sleep(20)
PYEOF

        # Run python script in background and capture output
        python3 "${ZOMBIE_SCRIPT}" > "${LAB_WORKDIR}/pids.txt" &
        PY_PARENT_PID=$!
        CHILD_PIDS+=("${PY_PARENT_PID}")

        # Wait briefly for parent and child to fork
        sleep 0.5

        if [[ -f "${LAB_WORKDIR}/pids.txt" ]]; then
            source "${LAB_WORKDIR}/pids.txt"
            CHILD_PIDS+=("${CHILD_PID}")

            echo "Parent PID: ${PARENT_PID}"
            echo "Child PID: ${CHILD_PID}"
            echo ""
            echo "--- Inspecting Child Process State in Process Table ---"
            ps -o pid,ppid,stat,comm -p "${CHILD_PID}"
            echo "Observation: Child state is 'Z' (defunct / zombie) because parent has not reaped it via wait()."

            echo ""
            echo "--- Terminating Parent Process (${PARENT_PID}) ---"
            kill -KILL "${PARENT_PID}" 2>/dev/null || true
            sleep 0.3

            echo "--- Verifying Zombie Removal ---"
            if ps -p "${CHILD_PID}" >/dev/null 2>&1; then
                echo "Child still present"
            else
                echo "Zombie process ${CHILD_PID} successfully reaped by PID 1 (init) upon parent termination."
            fi
        fi
    else
        echo "python3 not installed; zombie demo skipped"
    fi
} >> "${OUT_G}"
echo "done -> outputs/demo-g-zombie.txt"

echo ""
echo "=== Process Signals Lab Complete! Cleaned up lab-workdir cleanly. ==="
