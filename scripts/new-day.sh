#!/usr/bin/env bash
set -euo pipefail

# Determine repository root from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
    echo "Usage: $0 <day-number 1-30> <slug>"
    echo "Example: $0 1 linux-architecture"
    exit 1
}

if [[ $# -ne 2 ]]; then
    usage
fi

DAY_INPUT="$1"
SLUG_INPUT="$2"

# Validate day number is an integer from 1 to 30
if ! [[ "${DAY_INPUT}" =~ ^[0-9]+$ ]] || [ "${DAY_INPUT}" -lt 1 ] || [ "${DAY_INPUT}" -gt 30 ]; then
    echo "Error: Day number must be an integer between 1 and 30 (got: '${DAY_INPUT}')." >&2
    exit 1
fi

# Validate slug matches ^[a-z0-9-]+$
if ! [[ "${SLUG_INPUT}" =~ ^[a-z0-9-]+$ ]]; then
    echo "Error: Slug must contain only lowercase letters, digits, and hyphens (got: '${SLUG_INPUT}')." >&2
    exit 1
fi

# Format with two-digit zero padding
PADDED_DAY=$(printf "%02d" "${DAY_INPUT}")
TARGET_DIR="${REPO_ROOT}/day-${PADDED_DAY}-${SLUG_INPUT}"
TEMPLATE_DIR="${REPO_ROOT}/templates/day-template"

if [[ ! -d "${TEMPLATE_DIR}" ]]; then
    echo "Error: Template directory not found at ${TEMPLATE_DIR}." >&2
    exit 1
fi

if [[ -e "${TARGET_DIR}" ]]; then
    echo "Error: Target directory '${TARGET_DIR}' already exists." >&2
    exit 1
fi

# Copy template to target folder
cp -r "${TEMPLATE_DIR}" "${TARGET_DIR}"

echo "Successfully created day lab directory: day-${PADDED_DAY}-${SLUG_INPUT}"
