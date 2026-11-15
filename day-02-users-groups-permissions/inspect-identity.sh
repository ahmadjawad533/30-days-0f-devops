#!/usr/bin/env bash
# ==============================================================================
# inspect-identity.sh - Read-Only Linux Identity and Permissions Inspection
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# This script is strictly READ-ONLY. It never runs sudo, never modifies /etc,
# never alters user or group databases, and does not print sensitive files
# like /etc/shadow, /etc/sudoers, or private keys.
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

echo "=== Starting Linux Identity Inspection (Read-Only) ==="

# ------------------------------------------------------------------------------
# Section 01: Identity
# ------------------------------------------------------------------------------
echo -n "[01/11] Inspecting User and Group Identity... "
OUT_01="${OUTPUT_DIR}/01-identity.txt"
log_header "${OUT_01}" "id; id -un; id -gn; id -Gn"
{
    echo "--- Full Identity (id) ---"
    id 2>&1 || echo "id command failed"
    echo ""
    echo "--- User Name (id -un) ---"
    id -un 2>&1 || echo "id -un failed"
    echo ""
    echo "--- Primary Group Name (id -gn) ---"
    id -gn 2>&1 || echo "id -gn failed"
    echo ""
    echo "--- All Group Memberships (id -Gn) ---"
    id -Gn 2>&1 || echo "id -Gn failed"
} >> "${OUT_01}"
echo "done -> outputs/01-identity.txt"

# ------------------------------------------------------------------------------
# Section 02: Account Record
# ------------------------------------------------------------------------------
echo -n "[02/11] Inspecting Account Record in NSS Databases... "
OUT_02="${OUTPUT_DIR}/02-account-record.txt"
log_header "${OUT_02}" "getent passwd \$(id -un); getent group \$(id -gn) | cut -d: -f1,3"
{
    CURRENT_USER="$(id -un 2>/dev/null || whoami)"
    CURRENT_GROUP="$(id -gn 2>/dev/null || true)"

    echo "--- Passwd Database Entry for Current User ---"
    if command -v getent >/dev/null 2>&1; then
        getent passwd "${CURRENT_USER}" 2>&1 || echo "getent passwd failed"
    else
        grep "^${CURRENT_USER}:" /etc/passwd 2>/dev/null || echo "getent not found and /etc/passwd unreadable"
    fi

    echo ""
    echo "--- Primary Group Name and GID Only ---"
    if command -v getent >/dev/null 2>&1; then
        getent group "${CURRENT_GROUP}" 2>/dev/null | cut -d: -f1,3
    else
        grep "^${CURRENT_GROUP}:" /etc/group 2>/dev/null | cut -d: -f1,3 || echo "group entry unavailable"
    fi
} >> "${OUT_02}"
echo "done -> outputs/02-account-record.txt"

# ------------------------------------------------------------------------------
# Section 03: Account File Metadata
# ------------------------------------------------------------------------------
echo -n "[03/11] Inspecting Account File Metadata (No Contents)... "
OUT_03="${OUTPUT_DIR}/03-account-file-metadata.txt"
log_header "${OUT_03}" "ls -l /etc/passwd /etc/group /etc/shadow"
{
    echo "--- Permissions and Ownership of System Auth Databases ---"
    ls -l /etc/passwd /etc/group /etc/shadow 2>&1 || echo "ls command failed"
} >> "${OUT_03}"
echo "done -> outputs/03-account-file-metadata.txt"

# ------------------------------------------------------------------------------
# Section 04: Account Counts and UID Ranges
# ------------------------------------------------------------------------------
echo -n "[04/11] Inspecting Account Counts and UID Ranges... "
OUT_04="${OUTPUT_DIR}/04-account-counts.txt"
log_header "${OUT_04}" "awk UID count (<1000 vs >=1000); grep UID_MIN/MAX /etc/login.defs"
{
    echo "--- Account Counts by UID Boundary ---"
    if [[ -r /etc/passwd ]] && command -v awk >/dev/null 2>&1; then
        awk -F: '
            BEGIN { sys=0; reg=0 }
            {
                if ($3 < 1000) sys++;
                else reg++;
            }
            END {
                print "System accounts (UID < 1000):  " sys;
                print "Regular accounts (UID >= 1000): " reg;
                print "Total accounts in /etc/passwd:  " (sys + reg);
            }
        ' /etc/passwd 2>&1
    else
        echo "Unable to parse /etc/passwd or awk not available"
    fi

    echo ""
    echo "--- UID Configuration from /etc/login.defs ---"
    if [[ -r /etc/login.defs ]] && command -v grep >/dev/null 2>&1; then
        grep -E '^[[:space:]]*UID_(MIN|MAX)' /etc/login.defs 2>&1 || echo "UID_MIN/MAX not found"
    else
        echo "/etc/login.defs unreadable or grep missing"
    fi
} >> "${OUT_04}"
echo "done -> outputs/04-account-counts.txt"

# ------------------------------------------------------------------------------
# Section 05: Login Shells
# ------------------------------------------------------------------------------
echo -n "[05/11] Inspecting Distinct Login Shells... "
OUT_05="${OUTPUT_DIR}/05-login-shells.txt"
log_header "${OUT_05}" "cut -d: -f7 /etc/passwd | sort | uniq -c"
{
    echo "--- Distinct Login Shells and Counts ---"
    if [[ -r /etc/passwd ]] && command -v cut >/dev/null 2>&1 && command -v sort >/dev/null 2>&1 && command -v uniq >/dev/null 2>&1; then
        cut -d: -f7 /etc/passwd | sort | uniq -c | sort -nr 2>&1
    else
        echo "Required utilities or /etc/passwd unavailable"
    fi
} >> "${OUT_05}"
echo "done -> outputs/05-login-shells.txt"

# ------------------------------------------------------------------------------
# Section 06: Administrative Groups
# ------------------------------------------------------------------------------
echo -n "[06/11] Inspecting Admin Groups (Name & GID only)... "
OUT_06="${OUTPUT_DIR}/06-admin-groups.txt"
log_header "${OUT_06}" "getent group wheel / sudo | cut -d: -f1,3"
{
    echo "--- Admin Group Identifiers (Members Hidden for Safety) ---"
    for grp in wheel sudo; do
        if command -v getent >/dev/null 2>&1; then
            ENTRY="$(getent group "${grp}" 2>/dev/null | cut -d: -f1,3 || true)"
            if [[ -n "${ENTRY}" ]]; then
                echo "Group '${grp}': ${ENTRY}"
            else
                echo "Group '${grp}': (not present on this system)"
            fi
        fi
    done
} >> "${OUT_06}"
echo "done -> outputs/06-admin-groups.txt"

# ------------------------------------------------------------------------------
# Section 07: Umask
# ------------------------------------------------------------------------------
echo -n "[07/11] Inspecting Umask Settings... "
OUT_07="${OUTPUT_DIR}/07-umask.txt"
log_header "${OUT_07}" "umask; umask -S"
{
    echo "--- Current Process Umask (Octal) ---"
    umask 2>&1 || echo "umask failed"
    echo ""
    echo "--- Current Process Umask (Symbolic) ---"
    umask -S 2>&1 || echo "umask -S failed"
} >> "${OUT_07}"
echo "done -> outputs/07-umask.txt"

# ------------------------------------------------------------------------------
# Section 08: Special Permission Bits (Sticky Bit & SUID)
# ------------------------------------------------------------------------------
echo -n "[08/11] Inspecting Special Permission Bits on System Paths... "
OUT_08="${OUTPUT_DIR}/08-special-bits.txt"
log_header "${OUT_08}" "ls -ld /tmp; stat -c '%A %U:%G %n' /usr/bin/passwd /usr/bin/sudo"
{
    echo "--- Sticky Bit on /tmp Directory ---"
    ls -ld /tmp 2>&1 || echo "ls -ld /tmp failed"
    echo ""
    echo "--- SUID Binaries Metadata ---"
    for bin in /usr/bin/passwd /usr/bin/sudo; do
        if [[ -e "${bin}" ]]; then
            stat -c '%A %U:%G %n' "${bin}" 2>&1
        else
            echo "${bin}: not found"
        fi
    done
} >> "${OUT_08}"
echo "done -> outputs/08-special-bits.txt"

# ------------------------------------------------------------------------------
# Section 09: SUID / SGID Inventory
# ------------------------------------------------------------------------------
echo -n "[09/11] Inspecting SUID/SGID Binaries Inventory... "
OUT_09="${OUTPUT_DIR}/09-suid-inventory.txt"
log_header "${OUT_09}" "find /usr/bin /usr/sbin -xdev -perm /6000 -type f | head -n 20 (and total count)"
{
    echo "--- First 20 SUID/SGID Files in /usr/bin and /usr/sbin ---"
    find /usr/bin /usr/sbin -xdev -perm /6000 -type f 2>/dev/null | head -n 20 || true
    echo ""
    echo "--- Total SUID/SGID Count in /usr/bin and /usr/sbin ---"
    COUNT=$(find /usr/bin /usr/sbin -xdev -perm /6000 -type f 2>/dev/null | wc -l || echo "0")
    echo "Total files with SUID or SGID set: ${COUNT}"
} >> "${OUT_09}"
echo "done -> outputs/09-suid-inventory.txt"

# ------------------------------------------------------------------------------
# Section 10: Home and SSH Directory Metadata
# ------------------------------------------------------------------------------
echo -n "[10/11] Inspecting Home and SSH Metadata (No Contents)... "
OUT_10="${OUTPUT_DIR}/10-home-ssh-metadata.txt"
log_header "${OUT_10}" "stat -c '%A %U:%G %n' \"\$HOME\" and ~/.ssh"
{
    echo "--- User Home Directory Metadata ---"
    stat -c '%A %U:%G %n' "${HOME}" 2>&1 || echo "stat on HOME failed"
    echo ""
    echo "--- User .ssh Directory Metadata (If Present) ---"
    if [[ -d "${HOME}/.ssh" ]]; then
        stat -c '%A %U:%G %n' "${HOME}/.ssh" 2>&1
        echo "(Note: Listing or reading inside ~/.ssh is strictly prohibited for security)"
    else
        echo "~/.ssh directory does not exist"
    fi
} >> "${OUT_10}"
echo "done -> outputs/10-home-ssh-metadata.txt"

# ------------------------------------------------------------------------------
# Section 11: Host Context Note
# ------------------------------------------------------------------------------
echo -n "[11/11] Writing Host Context Note... "
OUT_11="${OUTPUT_DIR}/11-context-note.txt"
log_header "${OUT_11}" "Host Context Note"
{
    echo "Host Environment: Local Linux Desktop / Development Workstation"
    echo "OS Distribution: CachyOS (Arch Linux family)"
    echo "Cloud Context: Not an AWS EC2 instance. No cloud provider metadata services or credentials used."
    echo "Safety Guarantee: All inspections performed in read-only mode using unprivileged user execution."
} >> "${OUT_11}"
echo "done -> outputs/11-context-note.txt"

echo ""
echo "=== Identity Inspection Complete! Real outputs stored in outputs/ ==="
