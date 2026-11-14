#!/usr/bin/env bash
# ==============================================================================
# inspect.sh - Linux Architecture Inspection Tool
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# This script is strictly READ-ONLY with respect to the system. It does not
# install/remove packages, does not run sudo, does not alter sysctl or kernel
# settings, does not kill processes, and does not inspect sensitive user credentials,
# environment variables, or private files.
# ==============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/outputs"
DAY_TMP_DIR="${SCRIPT_DIR}/tmp"

# Ensure output directory exists
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

echo "=== Starting Linux Architecture Inspection Lab (Read-Only) ==="

# ------------------------------------------------------------------------------
# Section 01: Kernel and OS Identification
# ------------------------------------------------------------------------------
echo -n "[01/10] Inspecting Kernel and OS Release... "
OUT_01="${OUTPUT_DIR}/01-kernel.txt"
log_header "${OUT_01}" "uname -r; uname -m; cat /etc/os-release"
{
    echo "--- Kernel Release (uname -r) ---"
    if command -v uname >/dev/null 2>&1; then
        uname -r 2>&1 || echo "uname -r failed"
    else
        echo "uname command not available"
    fi
    echo ""
    echo "--- Machine Architecture (uname -m) ---"
    if command -v uname >/dev/null 2>&1; then
        uname -m 2>&1 || echo "uname -m failed"
    else
        echo "uname command not available"
    fi
    echo ""
    echo "--- OS Release (/etc/os-release) ---"
    if [[ -f /etc/os-release ]]; then
        cat /etc/os-release 2>&1
    else
        echo "/etc/os-release not found"
    fi
} >> "${OUT_01}"
echo "done -> outputs/01-kernel.txt"

# ------------------------------------------------------------------------------
# Section 02: PID 1 and Process Tree
# ------------------------------------------------------------------------------
echo -n "[02/10] Inspecting PID 1 and Process Tree... "
OUT_02="${OUTPUT_DIR}/02-process-tree.txt"
log_header "${OUT_02}" "cat /proc/1/comm; ps -o pid,ppid,stat,comm -p 1,\$\$; pstree -p \$\$"
{
    echo "--- PID 1 Command Name (/proc/1/comm) ---"
    if [[ -r /proc/1/comm ]]; then
        cat /proc/1/comm 2>&1
    else
        echo "Unable to read /proc/1/comm"
    fi
    echo ""
    echo "--- Process Status for PID 1 and Current Shell (\$\$) ---"
    if command -v ps >/dev/null 2>&1; then
        ps -o pid,ppid,stat,comm -p "1,$$" 2>&1
    else
        echo "ps command not available"
    fi
    echo ""
    echo "--- Process Ancestry Tree (pstree -p \$\$) ---"
    if command -v pstree >/dev/null 2>&1; then
        pstree -p "$$" 2>&1
    else
        echo "pstree not installed; skipping process tree view"
    fi
} >> "${OUT_02}"
echo "done -> outputs/02-process-tree.txt"

# ------------------------------------------------------------------------------
# Section 03: Process States
# ------------------------------------------------------------------------------
echo -n "[03/10] Inspecting Process State Distribution... "
OUT_03="${OUTPUT_DIR}/03-process-states.txt"
log_header "${OUT_03}" "ps -eo stat --no-headers | cut -c1 | sort | uniq -c"
{
    echo "--- System Process State Counts ---"
    if command -v ps >/dev/null 2>&1 && command -v cut >/dev/null 2>&1 && command -v sort >/dev/null 2>&1 && command -v uniq >/dev/null 2>&1; then
        ps -eo stat --no-headers 2>/dev/null | cut -c1 | sort | uniq -c
        echo ""
        echo "Legend:"
        echo "  R: Running or runnable (on run queue)"
        echo "  S: Interruptible sleep (waiting for an event to complete)"
        echo "  D: Uninterruptible sleep (usually waiting for I/O)"
        echo "  Z: Defunct / zombie (terminated but not reaped by parent)"
        echo "  T: Stopped by job control signal or traced"
        echo "  I: Idle kernel thread"
    else
        echo "Required utilities (ps, cut, sort, uniq) not fully available"
    fi
} >> "${OUT_03}"
echo "done -> outputs/03-process-states.txt"

# ------------------------------------------------------------------------------
# Section 04: Memory Subsystem
# ------------------------------------------------------------------------------
echo -n "[04/10] Inspecting Memory Subsystem... "
OUT_04="${OUTPUT_DIR}/04-memory.txt"
log_header "${OUT_04}" "free -h; grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree):' /proc/meminfo"
{
    echo "--- Human Readable Memory Overview (free -h) ---"
    if command -v free >/dev/null 2>&1; then
        free -h 2>&1
    else
        echo "free command not available"
    fi
    echo ""
    echo "--- Selected /proc/meminfo Fields ---"
    if [[ -r /proc/meminfo ]] && command -v grep >/dev/null 2>&1; then
        grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree):' /proc/meminfo 2>&1
    else
        echo "/proc/meminfo not readable or grep missing"
    fi
} >> "${OUT_04}"
echo "done -> outputs/04-memory.txt"

# ------------------------------------------------------------------------------
# Section 05: Kernel Modules
# ------------------------------------------------------------------------------
echo -n "[05/10] Inspecting Loaded Kernel Modules... "
OUT_05="${OUTPUT_DIR}/05-modules.txt"
log_header "${OUT_05}" "lsmod | head -n 15"
{
    echo "--- Top 15 Loaded Kernel Modules (lsmod | head -n 15) ---"
    if command -v lsmod >/dev/null 2>&1 && command -v head >/dev/null 2>&1; then
        lsmod 2>&1 | head -n 15
    else
        echo "lsmod or head command not available"
    fi
} >> "${OUT_05}"
echo "done -> outputs/05-modules.txt"

# ------------------------------------------------------------------------------
# Section 06: Pseudo-Filesystems (VFS)
# ------------------------------------------------------------------------------
echo -n "[06/10] Inspecting Pseudo-Filesystems (/proc, /sys, findmnt)... "
OUT_06="${OUTPUT_DIR}/06-pseudo-filesystems.txt"
log_header "${OUT_06}" "ls /proc/self | head -n 20; ls /sys/class | head -n 20; findmnt -t proc,sysfs,devtmpfs,cgroup2"
{
    echo "--- Live Process Structure: ls /proc/self | head -n 20 ---"
    if [[ -d /proc/self ]] && command -v ls >/dev/null 2>&1 && command -v head >/dev/null 2>&1; then
        ls -1 /proc/self 2>&1 | head -n 20
    else
        echo "/proc/self unavailable or ls/head missing"
    fi
    echo ""
    echo "--- Kernel Device Classes: ls /sys/class | head -n 20 ---"
    if [[ -d /sys/class ]] && command -v ls >/dev/null 2>&1 && command -v head >/dev/null 2>&1; then
        ls -1 /sys/class 2>&1 | head -n 20
    else
        echo "/sys/class unavailable or ls/head missing"
    fi
    echo ""
    echo "--- Virtual Filesystem Mounts (proc, sysfs, devtmpfs, cgroup2) ---"
    if command -v findmnt >/dev/null 2>&1; then
        findmnt -t proc,sysfs,devtmpfs,cgroup2 2>&1 || echo "findmnt command failed"
    else
        echo "findmnt command not available"
    fi
} >> "${OUT_06}"
echo "done -> outputs/06-pseudo-filesystems.txt"

# ------------------------------------------------------------------------------
# Section 07: File Descriptors and Limits
# ------------------------------------------------------------------------------
echo -n "[07/10] Inspecting File Descriptors and Limits... "
OUT_07="${OUTPUT_DIR}/07-file-descriptors.txt"
log_header "${OUT_07}" "ls -l /proc/self/fd; ulimit -n; ulimit -Hn"
{
    echo "--- Process File Descriptors (ls -l /proc/self/fd) ---"
    if [[ -d /proc/self/fd ]] && command -v ls >/dev/null 2>&1; then
        ls -l /proc/self/fd 2>&1
    else
        echo "/proc/self/fd unavailable or ls missing"
    fi
    echo ""
    echo "--- Open File Limits ---"
    echo "Soft limit (ulimit -n): $(ulimit -n 2>&1 || echo 'failed')"
    echo "Hard limit (ulimit -Hn): $(ulimit -Hn 2>&1 || echo 'failed')"
} >> "${OUT_07}"
echo "done -> outputs/07-file-descriptors.txt"

# ------------------------------------------------------------------------------
# Section 08: Namespaces and Cgroups
# ------------------------------------------------------------------------------
echo -n "[08/10] Inspecting Namespaces and Cgroups... "
OUT_08="${OUTPUT_DIR}/08-namespaces-cgroups.txt"
log_header "${OUT_08}" "ls -l /proc/self/ns; cat /proc/self/cgroup"
{
    echo "--- Process Namespaces (ls -l /proc/self/ns) ---"
    if [[ -d /proc/self/ns ]] && command -v ls >/dev/null 2>&1; then
        ls -l /proc/self/ns 2>&1
    else
        echo "/proc/self/ns unavailable or ls missing"
    fi
    echo ""
    echo "--- Process Control Group Membership (cat /proc/self/cgroup) ---"
    if [[ -r /proc/self/cgroup ]]; then
        cat /proc/self/cgroup 2>&1
    else
        echo "/proc/self/cgroup not readable"
    fi
} >> "${OUT_08}"
echo "done -> outputs/08-namespaces-cgroups.txt"

# ------------------------------------------------------------------------------
# Section 09: System Load
# ------------------------------------------------------------------------------
echo -n "[09/10] Inspecting System Load Average... "
OUT_09="${OUTPUT_DIR}/09-load.txt"
log_header "${OUT_09}" "cat /proc/loadavg"
{
    echo "--- System Load Average (/proc/loadavg) ---"
    if [[ -r /proc/loadavg ]]; then
        cat /proc/loadavg 2>&1
        echo ""
        echo "Format: <1 min avg> <5 min avg> <15 min avg> <runnable/total entities> <last created PID>"
    else
        echo "/proc/loadavg not readable"
    fi
} >> "${OUT_09}"
echo "done -> outputs/09-load.txt"

# ------------------------------------------------------------------------------
# Section 10: Optional System Call Tracing (strace demo)
# ------------------------------------------------------------------------------
echo -n "[10/10] Inspecting System Calls (strace demo)... "
OUT_10="${OUTPUT_DIR}/10-strace.txt"
log_header "${OUT_10}" "strace -f -e trace=openat,read,write,execve cat <file>"
if command -v strace >/dev/null 2>&1; then
    mkdir -p "${DAY_TMP_DIR}"
    TMP_FILE="$(mktemp "${DAY_TMP_DIR}/trace_XXXXXX.txt")"
    echo "Linux Architecture: Syscall trace demonstration." > "${TMP_FILE}"

    {
        echo "--- strace output for: cat ${TMP_FILE} ---"
        strace -f -e trace=openat,read,write,execve cat "${TMP_FILE}" 2>&1
    } >> "${OUT_10}"

    # Clean up only the specific temp file created
    rm -f "${TMP_FILE}"
    # Remove tmp dir if empty
    rmdir "${DAY_TMP_DIR}" 2>/dev/null || true

    echo "done -> outputs/10-strace.txt"
else
    {
        echo "strace not installed; section skipped"
    } >> "${OUT_10}"
    echo "skipped (strace not installed) -> outputs/10-strace.txt"
fi

echo ""
echo "=== Inspection Complete! Real outputs captured in outputs/ ==="
