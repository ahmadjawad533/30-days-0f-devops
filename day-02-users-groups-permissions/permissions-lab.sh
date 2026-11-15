#!/usr/bin/env bash
# ==============================================================================
# permissions-lab.sh - Project-Local Linux Permissions Laboratory
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# Strictly PROJECT-LOCAL and unprivileged. No sudo used.
# All temporary directories and files are restricted solely to ./lab-workdir/
# within this lab folder and removed cleanly at the end.
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

cleanup_lab_workdir() {
    # Guarded check to ensure path is exactly this lab-workdir
    if [[ -n "${LAB_WORKDIR:-}" && "${LAB_WORKDIR}" != "/" && "${LAB_WORKDIR}" != "${HOME:-}" && "${LAB_WORKDIR}" == "${SCRIPT_DIR}/lab-workdir" ]]; then
        # Restore write permissions on any nested dirs before deletion to prevent rm error
        chmod -R u+rwx "${LAB_WORKDIR}" 2>/dev/null || true
        rm -rf "${LAB_WORKDIR}"
    fi
}
trap cleanup_lab_workdir EXIT

echo "=== Starting Project-Local Permissions Lab (Unprivileged) ==="

# ------------------------------------------------------------------------------
# Demo A: ls -l and stat; chmod octal and symbolic modes
# ------------------------------------------------------------------------------
echo -n "[Demo A] Testing chmod with octal and symbolic modes... "
OUT_A="${OUTPUT_DIR}/demo-a-chmod.txt"
log_header "${OUT_A}" "chmod with octal and symbolic modes"
{
    FILE_A="${LAB_WORKDIR}/file_a.txt"
    touch "${FILE_A}"
    echo "--- Initial State ---"
    stat -c 'Mode: %a (%A)  Owner: %U  Group: %G  File: %n' "${FILE_A}"

    echo ""
    echo "--- After chmod 640 (Octal: u=rw, g=r, o=---) ---"
    chmod 640 "${FILE_A}"
    stat -c 'Mode: %a (%A)  File: %n' "${FILE_A}"

    echo ""
    echo "--- After chmod g+w,o+r (Symbolic addition) ---"
    chmod g+w,o+r "${FILE_A}"
    stat -c 'Mode: %a (%A)  File: %n' "${FILE_A}"

    echo ""
    echo "--- After chmod 400 (Read-only owner) ---"
    chmod 400 "${FILE_A}"
    stat -c 'Mode: %a (%A)  File: %n' "${FILE_A}"
} >> "${OUT_A}"
echo "done -> outputs/demo-a-chmod.txt"

# ------------------------------------------------------------------------------
# Demo B: Umask in a Subshell (077 vs 022)
# ------------------------------------------------------------------------------
echo -n "[Demo B] Testing umask impact in isolated subshells... "
OUT_B="${OUTPUT_DIR}/demo-b-umask.txt"
log_header "${OUT_B}" "umask in isolated subshells (077 vs 022)"
{
    echo "--- Parent Shell Initial Umask ---"
    PARENT_UMASK="$(umask)"
    echo "Parent umask: ${PARENT_UMASK}"

    echo ""
    echo "--- Subshell with umask 077 (Restricted: Owner Only) ---"
    (
        umask 077
        F77="${LAB_WORKDIR}/file_077.txt"
        D77="${LAB_WORKDIR}/dir_077"
        touch "${F77}"
        mkdir "${D77}"
        stat -c 'File (077): %a (%A)  %n' "${F77}"
        stat -c 'Dir  (077): %a (%A)  %n' "${D77}"
    )

    echo ""
    echo "--- Subshell with umask 022 (Standard Linux Default) ---"
    (
        umask 022
        F22="${LAB_WORKDIR}/file_022.txt"
        D22="${LAB_WORKDIR}/dir_022"
        touch "${F22}"
        mkdir "${D22}"
        stat -c 'File (022): %a (%A)  %n' "${F22}"
        stat -c 'Dir  (022): %a (%A)  %n' "${D22}"
    )

    echo ""
    echo "--- Parent Shell Final Umask Verification ---"
    CURRENT_PARENT_UMASK="$(umask)"
    echo "Parent umask remaining untouched: ${CURRENT_PARENT_UMASK}"
} >> "${OUT_B}"
echo "done -> outputs/demo-b-umask.txt"

# ------------------------------------------------------------------------------
# Demo C: Directory Semantics (r-x vs r-- vs --x)
# ------------------------------------------------------------------------------
echo -n "[Demo C] Testing directory semantics (read vs execute)... "
OUT_C="${OUTPUT_DIR}/demo-c-directory-semantics.txt"
log_header "${OUT_C}" "Directory semantics: read without execute vs execute without read"
{
    DIR_R_ONLY="${LAB_WORKDIR}/dir_read_only"
    DIR_X_ONLY="${LAB_WORKDIR}/dir_exec_only"
    mkdir -p "${DIR_R_ONLY}" "${DIR_X_ONLY}"

    echo "content-in-read-dir" > "${DIR_R_ONLY}/target.txt"
    echo "content-in-exec-dir" > "${DIR_X_ONLY}/target.txt"

    chmod 400 "${DIR_R_ONLY}"  # Read only (no execute)
    chmod 100 "${DIR_X_ONLY}"  # Execute only (no read/list)

    echo "=== Case 1: Directory with READ but NO EXECUTE (mode 400) ==="
    echo "Attempting 'ls' (reads directory directory-table entries):"
    ls "${DIR_R_ONLY}" 2>&1 || true
    echo "Attempting 'cd' (requires execute bit to traverse):"
    ( cd "${DIR_R_ONLY}" ) 2>&1 || true
    echo "Attempting 'cat' of known file (requires traversal to resolve inode):"
    cat "${DIR_R_ONLY}/target.txt" 2>&1 || true

    echo ""
    echo "=== Case 2: Directory with EXECUTE but NO READ (mode 100) ==="
    echo "Attempting 'ls' (fails because read bit is missing):"
    ls "${DIR_X_ONLY}" 2>&1 || true
    echo "Attempting 'cd' (succeeds because execute allows traversal):"
    ( cd "${DIR_X_ONLY}" && pwd ) 2>&1 || true
    echo "Attempting 'cat' of known file (succeeds! Traversal resolves inode without directory listing):"
    cat "${DIR_X_ONLY}/target.txt" 2>&1 || true

    # Restore write and execute so clean deletion works
    chmod 700 "${DIR_R_ONLY}" "${DIR_X_ONLY}"
} >> "${OUT_C}"
echo "done -> outputs/demo-c-directory-semantics.txt"

# ------------------------------------------------------------------------------
# Demo D: File Deletion Depends on Directory Permissions
# ------------------------------------------------------------------------------
echo -n "[Demo D] Testing deletion dependency on parent directory... "
OUT_D="${OUTPUT_DIR}/demo-d-delete-semantics.txt"
log_header "${OUT_D}" "File deletion depends on parent directory write permissions"
{
    DIR_DEL="${LAB_WORKDIR}/delete_demo_dir"
    mkdir -p "${DIR_DEL}"

    FILE_RO="${DIR_DEL}/read_only_file.txt"
    echo "I am a read-only file" > "${FILE_RO}"
    chmod 444 "${FILE_RO}"

    echo "--- Case 1: Removing mode 444 file from WRITABLE directory (mode 755) ---"
    stat -c 'File: %a (%A)  Parent Dir: %a (%A)' "${FILE_RO}" "${DIR_DEL}"
    echo "Attempting rm -f:"
    rm -f "${FILE_RO}" 2>&1 && echo "SUCCESS: Read-only file deleted because parent directory has write permission!"

    echo ""
    FILE_LOCKED="${DIR_DEL}/file_in_ro_dir.txt"
    echo "Another file" > "${FILE_LOCKED}"
    chmod 777 "${FILE_LOCKED}" # File itself has full permissions
    chmod 555 "${DIR_DEL}"     # Make parent directory READ-ONLY (no write)

    echo "--- Case 2: Removing mode 777 file from READ-ONLY directory (mode 555) ---"
    stat -c 'File: %a (%A)  Parent Dir: %a (%A)' "${FILE_LOCKED}" "${DIR_DEL}"
    echo "Attempting rm -f:"
    rm -f "${FILE_LOCKED}" 2>&1 || echo "FAILED as expected: Cannot modify directory table when parent lacks write bit."

    # Restore directory write permission
    chmod 755 "${DIR_DEL}"
} >> "${OUT_D}"
echo "done -> outputs/demo-d-delete-semantics.txt"

# ------------------------------------------------------------------------------
# Demo E: Owner Class Wins
# ------------------------------------------------------------------------------
echo -n "[Demo E] Testing Owner-Class-Wins evaluation rule... "
OUT_E="${OUTPUT_DIR}/demo-e-owner-wins.txt"
log_header "${OUT_E}" "Owner class wins: kernel evaluates only owner bits when UID matches"
{
    FILE_E="${LAB_WORKDIR}/owner_trap.txt"
    echo "Secret text that owner cannot read" > "${FILE_E}"

    # Mode 047: Owner: --- (no perms), Group: r-- (read), Other: rwx (read/write/exec)
    chmod 047 "${FILE_E}"

    echo "--- File Permissions and Ownership ---"
    stat -c 'Mode: %a (%A)  Owner: %U  Group: %G' "${FILE_E}"

    echo ""
    echo "Current Process User: $(id -un) (Matches file owner)"
    echo "Attempting 'cat' as file owner:"
    cat "${FILE_E}" 2>&1 || echo "DENIED (EACCES): Kernel found matching owner UID, checked owner bits (---), and immediately denied access. Group (r--) and Other (rwx) were never evaluated."
} >> "${OUT_E}"
echo "done -> outputs/demo-e-owner-wins.txt"

# ------------------------------------------------------------------------------
# Demo F: Sticky Bit on Directory
# ------------------------------------------------------------------------------
echo -n "[Demo F] Demonstrating Sticky Bit on shared directory... "
OUT_F="${OUTPUT_DIR}/demo-f-sticky-bit.txt"
log_header "${OUT_F}" "Sticky bit behavior on directories (mode 1777)"
{
    DIR_STICKY="${LAB_WORKDIR}/shared_sticky"
    mkdir -p "${DIR_STICKY}"
    chmod 1777 "${DIR_STICKY}"

    echo "--- Sticky Directory Attributes ---"
    ls -ld "${DIR_STICKY}"
    stat -c 'Mode: %a (%A)  Sticky bit indicator: %A' "${DIR_STICKY}"
    echo ""
    echo "Explanation: When the sticky bit (1000 / 't') is set on a world-writable directory (e.g. /tmp),"
    echo "unprivileged users can create files, but can ONLY delete or rename files they personally own"
    echo "or if they own the parent directory (or root)."
} >> "${OUT_F}"
echo "done -> outputs/demo-f-sticky-bit.txt"

# ------------------------------------------------------------------------------
# Demo G: SGID Directory (Group Inheritance)
# ------------------------------------------------------------------------------
echo -n "[Demo G] Testing SGID directory group inheritance... "
OUT_G="${OUTPUT_DIR}/demo-g-setgid-dir.txt"
log_header "${OUT_G}" "setgid directory and group inheritance"
{
    PRIMARY_GRP="$(id -gn)"
    # Find any group other than primary
    SUPP_GRP="$(id -Gn | tr ' ' '\n' | grep -v "^${PRIMARY_GRP}$" | head -n 1 || true)"

    if [[ -n "${SUPP_GRP}" ]]; then
        DIR_SGID="${LAB_WORKDIR}/sgid_dir"
        mkdir -p "${DIR_SGID}"
        chgrp "${SUPP_GRP}" "${DIR_SGID}" 2>/dev/null || true
        chmod 2775 "${DIR_SGID}" # setgid bit

        echo "--- SGID Directory Configuration ---"
        stat -c 'Directory: %n  Mode: %a (%A)  Group: %G' "${DIR_SGID}"

        FILE_INSIDE="${DIR_SGID}/inherited_file.txt"
        touch "${FILE_INSIDE}"
        echo ""
        echo "--- File Created Inside SGID Directory ---"
        stat -c 'Created File: %n  Mode: %a (%A)  Group: %G' "${FILE_INSIDE}"
        echo "Observation: File automatically inherited parent directory's group '${SUPP_GRP}' rather than process primary group '${PRIMARY_GRP}'."
    else
        echo "no supplementary group; setgid demo skipped"
    fi
} >> "${OUT_G}"
echo "done -> outputs/demo-g-setgid-dir.txt"

# ------------------------------------------------------------------------------
# Demo H: namei -l Path Traversal Resolution
# ------------------------------------------------------------------------------
echo -n "[Demo H] Inspecting nested path resolution with namei... "
OUT_H="${OUTPUT_DIR}/demo-h-namei.txt"
log_header "${OUT_H}" "namei -l nested path resolution"
{
    NESTED_DIR="${LAB_WORKDIR}/parent/child/grandchild"
    mkdir -p "${NESTED_DIR}"
    TARGET_NESTED="${NESTED_DIR}/app.conf"
    touch "${TARGET_NESTED}"

    if command -v namei >/dev/null 2>&1; then
        echo "--- namei -l Path Breakdown ---"
        namei -l "${TARGET_NESTED}" 2>&1
    else
        echo "namei command not available; skipped"
    fi
} >> "${OUT_H}"
echo "done -> outputs/demo-h-namei.txt"

# ------------------------------------------------------------------------------
# Demo I: POSIX Access Control Lists (ACLs)
# ------------------------------------------------------------------------------
echo -n "[Demo I] Checking POSIX ACL support (setfacl/getfacl)... "
OUT_I="${OUTPUT_DIR}/demo-i-acls.txt"
log_header "${OUT_I}" "POSIX Access Control Lists (ACL) check"
{
    if command -v setfacl >/dev/null 2>&1 && command -v getfacl >/dev/null 2>&1; then
        ACL_FILE="${LAB_WORKDIR}/acl_test.txt"
        touch "${ACL_FILE}"
        chmod 600 "${ACL_FILE}"

        # Attempt to set ACL for current user
        CURRENT_USER="$(id -un)"
        if setfacl -m "u:${CURRENT_USER}:r" "${ACL_FILE}" 2>/dev/null; then
            echo "--- getfacl Output on File with Extended ACL ---"
            getfacl "${ACL_FILE}" 2>&1
            echo ""
            echo "--- ls -l Indicator (+ sign shows extended ACL present) ---"
            ls -l "${ACL_FILE}"
        else
            echo "ACL tools not installed or unsupported; skipped"
        fi
    else
        echo "ACL tools not installed or unsupported; skipped"
    fi
} >> "${OUT_I}"
echo "done -> outputs/demo-i-acls.txt"

# ------------------------------------------------------------------------------
# Demo J: SSH Private Key Permission Rules (StrictModes)
# ------------------------------------------------------------------------------
echo -n "[Demo J] Demonstrating SSH private key permission constraints... "
OUT_J="${OUTPUT_DIR}/demo-j-ssh-key-rules.txt"
log_header "${OUT_J}" "SSH private key permission rules (StrictModes simulated)"
{
    FAKE_KEY="${LAB_WORKDIR}/fake_id_ed25519"
    # Create fake key placeholder text (NOT a real key)
    cat << 'KEYEOF' > "${FAKE_KEY}"
-----BEGIN OPENSSH PRIVATE KEY-----
FAKE-KEY-PLACEHOLDER-DEMONSTRATING-PERMISSIONS-ONLY-DO-NOT-USE
-----END OPENSSH PRIVATE KEY-----
KEYEOF

    echo "--- Case 1: Fake Key with Permissive Mode 644 (Simulating Client Rejection) ---"
    chmod 644 "${FAKE_KEY}"
    stat -c 'Mode: %a (%A)  File: %n' "${FAKE_KEY}"
    echo "Why OpenSSH client refuses this:"
    echo "  Permissions 0644 are too open. It is required that your private key files are NOT accessible by others."
    echo "  This private key will be ignored (UNPROTECTED PRIVATE KEY FILE!)."

    echo ""
    echo "--- Case 2: Fake Key with Correct Mode 600 (Restricted to Owner) ---"
    chmod 600 "${FAKE_KEY}"
    stat -c 'Mode: %a (%A)  File: %n' "${FAKE_KEY}"
    echo "Complies with OpenSSH requirement: Only file owner has read/write privileges."

    echo ""
    echo "--- SSH Server StrictModes Context ---"
    echo "On the server side, OpenSSH sshd enforces 'StrictModes yes' by default:"
    echo "  1. ~/.ssh must have permissions 700 (or at least no group/world write: max 755)."
    echo "  2. ~/.ssh/authorized_keys must have permissions 600 (or at least no group/world write: max 644)."
    echo "  3. The user's home directory (\$HOME) must NOT be writable by group or others."
} >> "${OUT_J}"
echo "done -> outputs/demo-j-ssh-key-rules.txt"

echo ""
echo "=== Permissions Lab Complete! Cleaned up lab-workdir cleanly. ==="
