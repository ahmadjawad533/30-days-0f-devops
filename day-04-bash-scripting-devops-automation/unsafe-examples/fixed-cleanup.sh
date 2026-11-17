#!/usr/bin/env bash
# ==============================================================================
# fixed-cleanup.sh - Hardened, Guarded Directory Cleanup Script
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# DEMONSTRATES FIXES:
# 1. Strict options: "set -uo pipefail"
# 2. Parameter expansion safety guard: ${TARGET_DIR:?error message}
# 3. Path boundaries: Ensures target resolves strictly inside an allowed workdir.
# 4. Dry-run mode by default to prevent accidental data erasure.
# ==============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DAY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ALLOWED_WORKDIR="${REPO_DAY_DIR}/lab-workdir"

log() {
    printf '[%s] %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*" >&2
}

die() {
    log "ERROR: $*"
    exit 3
}

usage() {
    cat << USAGEEOF
Usage: $(basename "$0") -t <target_directory> [-f] [-h]

Options:
  -t <dir>   Target directory to clean (must be inside lab-workdir)
  -f         Force deletion (without -f, script runs in dry-run mode)
  -h         Show this help message and exit
USAGEEOF
    exit 0
}

main() {
    local target_dir=""
    local force_delete=0

    while getopts ":t:fh" opt; do
        case "${opt}" in
            t) target_dir="${OPTARG}" ;;
            f) force_delete=1 ;;
            h) usage ;;
            :) die "Option -${OPTARG} requires an argument." ;;
            \?) die "Invalid option: -${OPTARG}." ;;
        esac
    done
    shift $((OPTIND - 1))

    # Guard 1: Parameter expansion guard ensuring target_dir is not empty or unset
    : "${target_dir:?Target directory (-t) must be specified and non-empty}"

    # Guard 2: Explicit refusal of root, home, or empty paths
    if [[ "${target_dir}" == "/" || "${target_dir}" == "${HOME:-}" ]]; then
        die "Refusing dangerous deletion target '${target_dir}'."
    fi

    if [[ ! -d "${target_dir}" ]]; then
        die "Target directory '${target_dir}' does not exist or is not a directory."
    fi

    # Guard 3: Canonical realpath boundary check
    local canonical_target
    canonical_target="$(realpath "${target_dir}")"
    local canonical_workdir
    canonical_workdir="$(realpath "${ALLOWED_WORKDIR}" 2>/dev/null || true)"

    if [[ -z "${canonical_workdir}" || ! -d "${canonical_workdir}" ]]; then
        die "Allowed workdir '${ALLOWED_WORKDIR}' does not exist."
    fi

    # Guard 4: Must be strictly a subdirectory inside lab-workdir (cannot be lab-workdir itself)
    if [[ "${canonical_target}" != "${canonical_workdir}/"* ]]; then
        die "Target '${canonical_target}' is outside allowed directory '${canonical_workdir}'."
    fi

    if [[ "${force_delete}" -eq 0 ]]; then
        log "[Dry-Run Mode] Would delete contents of: ${canonical_target}/*"
        log "Run with -f to perform real deletion."
        exit 0
    fi

    log "Cleaning contents of: ${canonical_target}"
    # Guard 5: Quoted expansion with nullglob
    shopt -s nullglob
    local items=("${canonical_target}"/*)
    shopt -u nullglob

    if [[ "${#items[@]}" -eq 0 ]]; then
        log "Directory is already empty."
        exit 0
    fi

    for item in "${items[@]}"; do
        log "Removing item: $(basename "${item}")"
        rm -rf "${item}"
    done

    log "Cleanup completed successfully."
    exit 0
}

main "$@"
