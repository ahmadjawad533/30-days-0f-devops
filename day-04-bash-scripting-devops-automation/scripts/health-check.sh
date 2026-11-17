#!/usr/bin/env bash
# ==============================================================================
# health-check.sh - Host Health and Service Readiness Inspector
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# Strictly READ-ONLY. Does not modify any system parameters.
# Does not inspect process names (-p) when probing listening ports.
#
# Exit codes:
#   0: OK (all metrics within normal thresholds)
#   1: WARNING (at least one metric exceeded warning threshold)
#   2: CRITICAL (at least one metric exceeded critical threshold: 2x warning)
#   3: Usage / argument error
# ==============================================================================

set -uo pipefail

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

log() {
    local level="$1"
    shift
    printf '[%s] [%s] %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "${level}" "$*" >&2
}

die() {
    local code="$1"
    shift
    log "ERROR" "$*"
    exit "${code}"
}

usage() {
    cat << USAGEEOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Read-only system health and readiness inspector.

Options:
  -p <path>        Filesystem mount path to inspect disk usage (default: ".")
  -d <percent>     Disk space warning threshold in percent (default: 80)
  -m <percent>     Available memory warning threshold in percent (default: 20)
  -l <multiplier>  Load average warning multiplier vs CPU count (default: 2)
  -t <port>        TCP port to check for active listener (optional)
  -h               Show this help message and exit

Exit codes:
  0: All metrics OK
  1: Warning threshold breached
  2: Critical threshold breached (metric > 2x warning threshold)
  3: Usage or parameter validation error
USAGEEOF
    exit 0
}

cleanup() {
    :
}
trap cleanup EXIT INT TERM

main() {
    local disk_path="."
    local disk_warn=80
    local mem_warn=20
    local load_warn=2
    local tcp_port=""

    while getopts ":p:d:m:l:t:h" opt; do
        case "${opt}" in
            p) disk_path="${OPTARG}" ;;
            d) disk_warn="${OPTARG}" ;;
            m) mem_warn="${OPTARG}" ;;
            l) load_warn="${OPTARG}" ;;
            t) tcp_port="${OPTARG}" ;;
            h) usage ;;
            :) die 3 "Option -${OPTARG} requires an argument. Use -h for help." ;;
            \?) die 3 "Invalid option: -${OPTARG}. Use -h for help." ;;
        esac
    done
    shift $((OPTIND - 1))

    # Validate inputs
    if [[ ! -e "${disk_path}" ]]; then
        die 3 "Disk path '${disk_path}' does not exist."
    fi

    if ! [[ "${disk_warn}" =~ ^[0-9]+$ ]] || [ "${disk_warn}" -lt 1 ] || [ "${disk_warn}" -gt 100 ]; then
        die 3 "Disk threshold (-d) must be an integer between 1 and 100 (got: '${disk_warn}')."
    fi

    if ! [[ "${mem_warn}" =~ ^[0-9]+$ ]] || [ "${mem_warn}" -lt 1 ] || [ "${mem_warn}" -gt 100 ]; then
        die 3 "Memory threshold (-m) must be an integer between 1 and 100 (got: '${mem_warn}')."
    fi

    if ! [[ "${load_warn}" =~ ^[0-9]+$ ]] || [ "${load_warn}" -lt 1 ]; then
        die 3 "Load multiplier (-l) must be a positive integer (got: '${load_warn}')."
    fi

    if [[ -n "${tcp_port}" ]]; then
        if ! [[ "${tcp_port}" =~ ^[0-9]+$ ]] || [ "${tcp_port}" -lt 1 ] || [ "${tcp_port}" -gt 65535 ]; then
            die 3 "TCP port (-t) must be an integer between 1 and 65535 (got: '${tcp_port}')."
        fi
    fi

    local overall_status=0
    local status_label="OK"

    echo "=============================================================================="
    echo "Host Health & Readiness Report"
    echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "=============================================================================="

    # 1. Disk usage check
    local disk_used_pct
    disk_used_pct=$(df -P "${disk_path}" | awk 'NR==2 {gsub(/%/, "", $5); print $5}')
    local disk_mount
    disk_mount=$(df -P "${disk_path}" | awk 'NR==2 {print $6}')

    local disk_crit=$(( disk_warn * 2 ))
    if [ "${disk_crit}" -gt 95 ]; then
        disk_crit=95
    fi

    local disk_status="OK"
    if [ "${disk_used_pct}" -ge "${disk_crit}" ]; then
        disk_status="CRITICAL"
        if [ "${overall_status}" -lt 2 ]; then overall_status=2; fi
    elif [ "${disk_used_pct}" -ge "${disk_warn}" ]; then
        disk_status="WARNING"
        if [ "${overall_status}" -lt 1 ]; then overall_status=1; fi
    fi
    printf "Disk Usage (%s on %s): %d%% (Warn: %d%%, Crit: %d%%) -> [%s]\n" \
        "${disk_path}" "${disk_mount}" "${disk_used_pct}" "${disk_warn}" "${disk_crit}" "${disk_status}"

    # 2. Available memory check
    local mem_total_kb=0
    local mem_avail_kb=0
    local mem_avail_pct=0

    if [[ -r /proc/meminfo ]]; then
        mem_total_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
        mem_avail_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
        if [ "${mem_total_kb}" -gt 0 ]; then
            mem_avail_pct=$(( (mem_avail_kb * 100) / mem_total_kb ))
        fi
    fi

    # Available memory: warning when available drops below threshold; critical when drops below half of warning threshold
    local mem_crit=$(( mem_warn / 2 ))
    if [ "${mem_crit}" -lt 2 ]; then
        mem_crit=2
    fi

    local mem_status="OK"
    if [ "${mem_avail_pct}" -le "${mem_crit}" ]; then
        mem_status="CRITICAL"
        if [ "${overall_status}" -lt 2 ]; then overall_status=2; fi
    elif [ "${mem_avail_pct}" -le "${mem_warn}" ]; then
        mem_status="WARNING"
        if [ "${overall_status}" -lt 1 ]; then overall_status=1; fi
    fi
    printf "Available Memory: %d%% (%d MB / %d MB) (Warn <= %d%%, Crit <= %d%%) -> [%s]\n" \
        "${mem_avail_pct}" "$(( mem_avail_kb / 1024 ))" "$(( mem_total_kb / 1024 ))" \
        "${mem_warn}" "${mem_crit}" "${mem_status}"

    # 3. CPU Load average check
    local cpu_count=1
    if command -v nproc >/dev/null 2>&1; then
        cpu_count=$(nproc)
    fi

    local load1="0.0"
    if [[ -r /proc/loadavg ]]; then
        load1=$(awk '{print $1}' /proc/loadavg)
    fi

    # Integer comparison for load threshold
    local load1_int
    load1_int=$(echo "${load1}" | cut -d. -f1)
    if [[ -z "${load1_int}" ]]; then load1_int=0; fi

    local load_warn_val=$(( cpu_count * load_warn ))
    local load_crit_val=$(( load_warn_val * 2 ))

    local load_status="OK"
    if [ "${load1_int}" -ge "${load_crit_val}" ]; then
        load_status="CRITICAL"
        if [ "${overall_status}" -lt 2 ]; then overall_status=2; fi
    elif [ "${load1_int}" -ge "${load_warn_val}" ]; then
        load_status="WARNING"
        if [ "${overall_status}" -lt 1 ]; then overall_status=1; fi
    fi
    printf "CPU Load (1m): %s across %d CPU cores (Warn: >= %d, Crit: >= %d) -> [%s]\n" \
        "${load1}" "${cpu_count}" "${load_warn_val}" "${load_crit_val}" "${load_status}"

    # 4. Failed systemd units count
    local failed_units_count="N/A"
    local systemd_status="OK"
    if command -v systemctl >/dev/null 2>&1; then
        failed_units_count=$(systemctl list-units --state=failed --no-legend --no-pager 2>/dev/null | wc -l || echo "0")
        if [ "${failed_units_count}" -gt 0 ]; then
            systemd_status="WARNING"
            if [ "${overall_status}" -lt 1 ]; then overall_status=1; fi
        fi
        printf "Failed systemd Units: %d -> [%s]\n" "${failed_units_count}" "${systemd_status}"
    else
        printf "Failed systemd Units: (systemctl not installed; skipped)\n"
    fi

    # 5. Optional TCP port listener check
    if [[ -n "${tcp_port}" ]]; then
        local port_listening=0
        if command -v ss >/dev/null 2>&1; then
            # Read-only check: ss -ltn (without -p to preserve process privacy)
            if ss -ltn | awk '{print $4}' | grep -qE "(:|^)${tcp_port}\$"; then
                port_listening=1
            fi
        fi

        if [[ "${port_listening}" -eq 1 ]]; then
            printf "TCP Port %s Listener: LISTENING -> [OK]\n" "${tcp_port}"
        else
            printf "TCP Port %s Listener: NOT LISTENING -> [WARNING]\n" "${tcp_port}"
            if [ "${overall_status}" -lt 1 ]; then overall_status=1; fi
        fi
    fi

    echo "------------------------------------------------------------------------------"
    case "${overall_status}" in
        0) status_label="HEALTHY (Exit 0)" ;;
        1) status_label="WARNING (Exit 1)" ;;
        2) status_label="CRITICAL (Exit 2)" ;;
    esac
    echo "Overall Health Assessment: ${status_label}"
    echo "=============================================================================="

    exit "${overall_status}"
}

main "$@"
