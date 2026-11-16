#!/usr/bin/env bash
# ==============================================================================
# inspect-systemd.sh - Read-Only systemd and Process Management Inspection
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# This script is strictly READ-ONLY. It never runs sudo, never modifies /etc
# or system unit directories, never starts/stops/restarts units, and does not
# run unrestricted ps aux or full journalctl dumps.
# ==============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/outputs"

mkdir -p "${OUTPUT_DIR}"

log_header() {
    local file="$1"
    local cmd="$2"
    {
        echo "# =============================================================================="
        echo "# Command: ${cmd}"
        echo "# Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "# =============================================================================="
        echo ""
    } > "${file}"
}

echo "=== Starting systemd and Process Inspection (Read-Only) ==="

# ------------------------------------------------------------------------------
# Section 01: Version and PID 1
# ------------------------------------------------------------------------------
echo -n "[01/12] Inspecting systemd Version and PID 1... "
OUT_01="${OUTPUT_DIR}/01-version-pid1.txt"
log_header "${OUT_01}" "systemctl --version | head -n 2; cat /proc/1/comm"
{
    echo "--- systemd Version ---"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --version 2>&1 | head -n 2
    else
        echo "systemctl command not available"
    fi
    echo ""
    echo "--- PID 1 Process Identity (/proc/1/comm) ---"
    if [[ -r /proc/1/comm ]]; then
        cat /proc/1/comm 2>&1
    else
        echo "Unable to read /proc/1/comm"
    fi
} >> "${OUT_01}"
echo "done -> outputs/01-version-pid1.txt"

# ------------------------------------------------------------------------------
# Section 02: System State and Default Target
# ------------------------------------------------------------------------------
echo -n "[02/12] Inspecting System State and Default Target... "
OUT_02="${OUTPUT_DIR}/02-system-state.txt"
log_header "${OUT_02}" "systemctl is-system-running; systemctl get-default"
{
    echo "--- Overall System Running State (is-system-running) ---"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl is-system-running 2>&1 || true
    else
        echo "systemctl command not available"
    fi
    echo ""
    echo "--- Default Boot Target (get-default) ---"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl get-default 2>&1 || echo "get-default failed"
    else
        echo "systemctl command not available"
    fi
} >> "${OUT_02}"
echo "done -> outputs/02-system-state.txt"

# ------------------------------------------------------------------------------
# Section 03: Running Services (Names Only)
# ------------------------------------------------------------------------------
echo -n "[03/12] Inspecting Running Services (Top 15 Names)... "
OUT_03="${OUTPUT_DIR}/03-running-services.txt"
log_header "${OUT_03}" "systemctl list-units --type=service --state=running --no-legend --no-pager | awk '{print \$1}' | head -n 15"
{
    echo "--- Active Running Service Unit Names (Top 15) ---"
    if command -v systemctl >/dev/null 2>&1 && command -v awk >/dev/null 2>&1; then
        systemctl list-units --type=service --state=running --no-legend --no-pager 2>/dev/null | awk '{print $1}' | head -n 15
    else
        echo "systemctl or awk not available"
    fi
} >> "${OUT_03}"
echo "done -> outputs/03-running-services.txt"

# ------------------------------------------------------------------------------
# Section 04: Unit File Counts
# ------------------------------------------------------------------------------
echo -n "[04/12] Inspecting Unit File State Distribution... "
OUT_04="${OUTPUT_DIR}/04-unit-file-counts.txt"
log_header "${OUT_04}" "systemctl list-unit-files --type=service --no-legend --no-pager | awk '{print \$2}' | sort | uniq -c"
{
    echo "--- Service Unit File States (Enabled / Disabled / Static / Masked) ---"
    if command -v systemctl >/dev/null 2>&1 && command -v awk >/dev/null 2>&1 && command -v sort >/dev/null 2>&1 && command -v uniq >/dev/null 2>&1; then
        systemctl list-unit-files --type=service --no-legend --no-pager 2>/dev/null | awk '{print $2}' | sort | uniq -c | sort -nr
    else
        echo "systemctl or text processing utilities not available"
    fi
} >> "${OUT_04}"
echo "done -> outputs/04-unit-file-counts.txt"

# ------------------------------------------------------------------------------
# Section 05: Failed Units
# ------------------------------------------------------------------------------
echo -n "[05/12] Inspecting Failed Units... "
OUT_05="${OUTPUT_DIR}/05-failed-units.txt"
log_header "${OUT_05}" "systemctl list-units --state=failed --no-legend --no-pager | awk '{print \$1}'"
{
    echo "--- Units in Failed State ---"
    if command -v systemctl >/dev/null 2>&1 && command -v awk >/dev/null 2>&1; then
        FAILED_OUTPUT="$(systemctl list-units --state=failed --no-legend --no-pager 2>/dev/null | awk '{print $1}' || true)"
        if [[ -n "${FAILED_OUTPUT}" ]]; then
            echo "${FAILED_OUTPUT}"
        else
            echo "(No failed units detected on the system)"
        fi
    else
        echo "systemctl or awk not available"
    fi
} >> "${OUT_05}"
echo "done -> outputs/05-failed-units.txt"

# ------------------------------------------------------------------------------
# Section 06: Example System Unit Definition
# ------------------------------------------------------------------------------
echo -n "[06/12] Inspecting Example Unit Definition (systemd-journald)... "
OUT_06="${OUTPUT_DIR}/06-example-unit.txt"
log_header "${OUT_06}" "systemctl cat systemd-journald.service --no-pager | head -n 40"
{
    echo "--- Unit File Contents: systemd-journald.service (First 40 Lines) ---"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl cat systemd-journald.service --no-pager 2>&1 | head -n 40
    else
        echo "systemctl not available"
    fi
} >> "${OUT_06}"
echo "done -> outputs/06-example-unit.txt"

# ------------------------------------------------------------------------------
# Section 07: Example Unit Properties
# ------------------------------------------------------------------------------
echo -n "[07/12] Inspecting Low-Level Unit Properties... "
OUT_07="${OUTPUT_DIR}/07-unit-properties.txt"
log_header "${OUT_07}" "systemctl show systemd-journald.service -p Id,Type,Restart,MainPID,ActiveState,SubState,ControlGroup,FragmentPath --no-pager"
{
    echo "--- Selected Property Values ---"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl show systemd-journald.service -p Id,Type,Restart,MainPID,ActiveState,SubState,ControlGroup,FragmentPath --no-pager 2>&1
    else
        echo "systemctl not available"
    fi
} >> "${OUT_07}"
echo "done -> outputs/07-unit-properties.txt"

# ------------------------------------------------------------------------------
# Section 08: Dependency View
# ------------------------------------------------------------------------------
echo -n "[08/12] Inspecting Target Dependency Tree... "
OUT_08="${OUTPUT_DIR}/08-dependencies.txt"
log_header "${OUT_08}" "systemctl list-dependencies default.target --no-pager | head -n 20"
{
    echo "--- Default Target Dependency Tree (First 20 Lines) ---"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl list-dependencies default.target --no-pager 2>&1 | head -n 20
    else
        echo "systemctl not available"
    fi
} >> "${OUT_08}"
echo "done -> outputs/08-dependencies.txt"

# ------------------------------------------------------------------------------
# Section 09: Boot Timing Analysis
# ------------------------------------------------------------------------------
echo -n "[09/12] Inspecting Boot Timing (systemd-analyze)... "
OUT_09="${OUTPUT_DIR}/09-boot-timing.txt"
log_header "${OUT_09}" "systemd-analyze | head -n 5"
{
    echo "--- Boot Timing Breakdown ---"
    if command -v systemd-analyze >/dev/null 2>&1; then
        systemd-analyze 2>&1 | head -n 5
    else
        echo "systemd-analyze command not available"
    fi
} >> "${OUT_09}"
echo "done -> outputs/09-boot-timing.txt"

# ------------------------------------------------------------------------------
# Section 10: Security & Sandboxing Exposure Overview
# ------------------------------------------------------------------------------
echo -n "[10/12] Inspecting Service Security Assessment... "
OUT_10="${OUTPUT_DIR}/10-security-overview.txt"
log_header "${OUT_10}" "systemd-analyze security --no-pager | head -n 15"
{
    echo "--- Service Exposure Scores (First 15 Lines) ---"
    if command -v systemd-analyze >/dev/null 2>&1; then
        systemd-analyze security --no-pager 2>&1 | head -n 15
    else
        echo "systemd-analyze command not available"
    fi
} >> "${OUT_10}"
echo "done -> outputs/10-security-overview.txt"

# ------------------------------------------------------------------------------
# Section 11: POSIX Signals Reference
# ------------------------------------------------------------------------------
echo -n "[11/12] Inspecting POSIX Signals Reference... "
OUT_11="${OUTPUT_DIR}/11-signals-reference.txt"
log_header "${OUT_11}" "kill -l"
{
    echo "--- Supported System Signals (kill -l) ---"
    kill -l 2>&1 || echo "kill -l failed"
} >> "${OUT_11}"
echo "done -> outputs/11-signals-reference.txt"

# ------------------------------------------------------------------------------
# Section 12: Own Shell Scheduling Priority
# ------------------------------------------------------------------------------
echo -n "[12/12] Inspecting Current Process Scheduling Priority... "
OUT_12="${OUTPUT_DIR}/12-shell-priority.txt"
log_header "${OUT_12}" "ps -o pid,ni,pri,stat,comm -p \$\$"
{
    echo "--- Shell Process Priority and Niceness ---"
    if command -v ps >/dev/null 2>&1; then
        ps -o pid,ni,pri,stat,comm -p "$$" 2>&1
    else
        echo "ps command not available"
    fi
} >> "${OUT_12}"
echo "done -> outputs/12-shell-priority.txt"

echo ""
echo "=== systemd Inspection Complete! Real outputs stored in outputs/ ==="
