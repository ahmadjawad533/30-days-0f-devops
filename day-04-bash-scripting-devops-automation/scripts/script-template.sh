#!/usr/bin/env bash
# ==============================================================================
# script-template.sh - Hardened, Reusable Bash Script Template
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# - Uses "set -uo pipefail" for strict error handling and unbound variable guards.
# - "set -e" is avoided in favor of explicit error checking and structured exits.
# - Includes standard log(), die(), usage(), input validation, and cleanup traps.
# ==============================================================================

set -uo pipefail

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
TMP_FILES=()

# Structured logging to stderr with ISO-8601 UTC timestamp
log() {
    local level="$1"
    shift
    printf '[%s] [%s] %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "${level}" "$*" >&2
}

# Standard exit on fatal error
die() {
    local code="$1"
    shift
    log "ERROR" "$*"
    exit "${code}"
}

# Cleanup handler triggered on script termination
cleanup() {
    local exit_code=$?
    for f in "${TMP_FILES[@]:-}"; do
        if [[ -f "${f}" ]]; then
            rm -f "${f}" 2>/dev/null || true
        fi
    done
    exit "${exit_code}"
}
trap cleanup EXIT INT TERM

usage() {
    cat << USAGEEOF
Usage: ${SCRIPT_NAME} [OPTIONS]

A hardened Bash script template demonstrating best practices.

Options:
  -v           Enable verbose logging
  -h           Show this help message and exit
USAGEEOF
    exit 0
}

main() {
    local verbose=0

    while getopts ":vh" opt; do
        case "${opt}" in
            v)
                verbose=1
                ;;
            h)
                usage
                ;;
            \?)
                die 3 "Invalid option: -${OPTARG}. Use -h for help."
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ "${verbose}" -eq 1 ]]; then
        log "INFO" "Verbose mode enabled."
    fi

    # Script logic goes here
    log "INFO" "Execution completed successfully."
    exit 0
}

main "$@"
