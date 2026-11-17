#!/usr/bin/env bash
# ==============================================================================
# backup-rotate.sh - Hardened Local Archive and Rotation Automation
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# - Operates strictly within the resolved day-04 lab-workdir path.
# - Refuses empty paths, "/", "$HOME", or any path outside lab-workdir.
# - Employs non-blocking flock to prevent concurrent overlapping executions.
# - Writes archive to a temporary file, verifies integrity with tar -tzf,
#   and promotes it atomically via mv.
# - Safe rotation removes only oldest files matching strict backup regex.
#
# Exit codes:
#   0: Success
#   3: Usage error or path-guard security refusal
#   4: Lock held (another backup is currently running)
#   5: Archive creation or verification failure
# ==============================================================================

set -uo pipefail

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DAY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Target allowed root for operations
ALLOWED_WORKDIR="${REPO_DAY_DIR}/lab-workdir"
LOCK_DIR="${REPO_DAY_DIR}/tmp"
LOCK_FILE="${LOCK_DIR}/backup.lock"
LOCK_FD=200

TEMP_ARCHIVE=""

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
Usage: ${SCRIPT_NAME} -s <source_dir> -d <dest_dir> -k <keep_count> [-n] [-h]

Options:
  -s <source_dir>  Directory to back up (must be inside lab-workdir)
  -d <dest_dir>    Directory to store archives (must be inside lab-workdir)
  -k <keep_count>  Number of most recent backups to retain (integer > 0)
  -n               Dry-run mode: Log planned actions without modifying filesystem
  -h               Show this help message and exit

Exit codes:
  0: Success
  3: Usage or path-guard error
  4: Lock contention (concurrency guard active)
  5: Archive or verification failure
USAGEEOF
    exit 0
}

cleanup() {
    local exit_code=$?
    # Clean up temp archive if it was left unpromoted
    if [[ -n "${TEMP_ARCHIVE:-}" && -f "${TEMP_ARCHIVE}" ]]; then
        log "DEBUG" "Cleaning up unpromoted temp archive: ${TEMP_ARCHIVE}"
        rm -f "${TEMP_ARCHIVE}" 2>/dev/null || true
    fi

    # Release lock
    if [[ -n "${LOCK_FD:-}" ]]; then
        eval "exec ${LOCK_FD}>&-" 2>/dev/null || true
    fi
    exit "${exit_code}"
}
trap cleanup EXIT INT TERM

# Path safety guard function
assert_path_under_workdir() {
    local path_label="$1"
    local raw_path="$2"

    if [[ -z "${raw_path}" ]]; then
        die 3 "Path guard violation: ${path_label} cannot be empty."
    fi

    if [[ "${raw_path}" == "/" || "${raw_path}" == "${HOME:-}" ]]; then
        die 3 "Path guard violation: Refusing dangerous path '${raw_path}' for ${path_label}."
    fi

    if [[ ! -e "${raw_path}" ]]; then
        die 3 "Path guard violation: ${path_label} '${raw_path}' does not exist."
    fi

    local canonical_path
    canonical_path="$(realpath "${raw_path}" 2>/dev/null || true)"
    local canonical_workdir
    canonical_workdir="$(realpath "${ALLOWED_WORKDIR}" 2>/dev/null || true)"

    if [[ -z "${canonical_workdir}" || ! -d "${canonical_workdir}" ]]; then
        die 3 "Path guard violation: Allowed workspace directory '${ALLOWED_WORKDIR}' is not available."
    fi

    # Ensure canonical path starts with canonical workdir prefix
    if [[ "${canonical_path}" != "${canonical_workdir}" && "${canonical_path}" != "${canonical_workdir}/"* ]]; then
        die 3 "Path guard refusal: ${path_label} '${raw_path}' resolves to '${canonical_path}', which is outside allowed directory '${canonical_workdir}'."
    fi
}

main() {
    local source_dir=""
    local dest_dir=""
    local keep_count=""
    local dry_run=0

    while getopts ":s:d:k:nh" opt; do
        case "${opt}" in
            s) source_dir="${OPTARG}" ;;
            d) dest_dir="${OPTARG}" ;;
            k) keep_count="${OPTARG}" ;;
            n) dry_run=1 ;;
            h) usage ;;
            :) die 3 "Option -${OPTARG} requires an argument. Use -h for help." ;;
            \?) die 3 "Invalid option: -${OPTARG}. Use -h for help." ;;
        esac
    done
    shift $((OPTIND - 1))

    # Validate presence of required options
    if [[ -z "${source_dir}" || -z "${dest_dir}" || -z "${keep_count}" ]]; then
        die 3 "Missing required options: -s, -d, and -k are mandatory. Use -h for usage."
    fi

    # Validate keep_count is integer > 0
    if ! [[ "${keep_count}" =~ ^[0-9]+$ ]] || [ "${keep_count}" -le 0 ]; then
        die 3 "Keep count (-k) must be an integer greater than 0 (got: '${keep_count}')."
    fi

    # Verify and enforce path guards
    assert_path_under_workdir "Source directory" "${source_dir}"
    assert_path_under_workdir "Destination directory" "${dest_dir}"

    local real_source
    real_source="$(realpath "${source_dir}")"
    local real_dest
    real_dest="$(realpath "${dest_dir}")"

    # Concurrency Lock (Non-blocking flock)
    mkdir -p "${LOCK_DIR}"
    exec 200>"${LOCK_FILE}"
    if ! flock -n 200; then
        die 4 "Lock held: Another instance of backup-rotate.sh is currently running (lockfile: ${LOCK_FILE})."
    fi

    log "INFO" "Concurrency lock acquired successfully."

    local timestamp
    timestamp="$(date -u +"%Y%m%d-%H%M%S")"
    local final_archive="${real_dest}/backup-${timestamp}.tar.gz"

    if [[ "${dry_run}" -eq 1 ]]; then
        log "DRY-RUN" "[Dry-Run] Would create archive from '${real_source}' into '${final_archive}'."
    else
        log "INFO" "Creating temporary archive in destination directory..."
        TEMP_ARCHIVE="$(mktemp "${real_dest}/tmp.backup.XXXXXX.tar.gz")"

        # Slowdown hook for testing trap cancellation if requested
        if [[ -n "${LAB04_TEST_SLOW_DELAY:-}" && "${LAB04_TEST_SLOW_DELAY}" =~ ^[0-9]+$ ]]; then
            log "DEBUG" "Simulating slow operation: sleeping for ${LAB04_TEST_SLOW_DELAY}s..."
            sleep "${LAB04_TEST_SLOW_DELAY}"
        fi

        # Execute tar archive creation
        if ! tar -czf "${TEMP_ARCHIVE}" -C "${real_source}" .; then
            die 5 "Failed to create tar archive from '${real_source}'."
        fi

        # Verify archive integrity
        log "INFO" "Verifying archive integrity with tar -tzf..."
        if ! tar -tzf "${TEMP_ARCHIVE}" >/dev/null 2>&1; then
            die 5 "Archive verification failed: corrupted archive created."
        fi

        # Atomic promotion via mv
        log "INFO" "Promoting temporary archive atomically to '${final_archive}'..."
        mv "${TEMP_ARCHIVE}" "${final_archive}"
        TEMP_ARCHIVE="" # Promoted; no longer needs temp cleanup
        log "INFO" "Backup created and verified successfully: $(basename "${final_archive}")"
    fi

    # Rotation Logic: Match strict naming pattern backup-YYYYmmdd-HHMMSS.tar.gz
    log "INFO" "Evaluating archive retention policy (keep count: ${keep_count})..."
    local archives=()
    while IFS= read -r archive_path; do
        if [[ -n "${archive_path}" ]]; then
            archives+=("${archive_path}")
        fi
    done < <(find "${real_dest}" -maxdepth 1 -type f -regextype posix-extended -regex ".*/backup-[0-9]{8}-[0-9]{6}\.tar\.gz$" | sort)

    local total_archives="${#archives[@]}"
    log "INFO" "Discovered ${total_archives} archives matching backup pattern in destination."

    if [ "${total_archives}" -gt "${keep_count}" ]; then
        local excess=$(( total_archives - keep_count ))
        log "INFO" "Rotating out ${excess} oldest archive(s)..."
        for (( i=0; i<excess; i++ )); do
            local old_archive="${archives[i]}"
            if [[ "${dry_run}" -eq 1 ]]; then
                log "DRY-RUN" "[Dry-Run] Would remove expired archive: ${old_archive}"
            else
                log "INFO" "Removing expired archive: $(basename "${old_archive}")"
                rm -f "${old_archive}"
            fi
        done
    else
        log "INFO" "Retention threshold satisfied (total ${total_archives} <= keep ${keep_count}). No rotation needed."
    fi

    log "INFO" "Backup and rotation completed successfully."
    exit 0
}

main "$@"
