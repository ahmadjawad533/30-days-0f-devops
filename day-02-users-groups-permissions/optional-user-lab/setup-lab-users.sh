#!/usr/bin/env bash
# ==============================================================================
# setup-lab-users.sh - Optional Multi-User Service Simulation Setup
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# This script creates real system users, groups, and a directory under /srv/.
# It MUST NOT be run by automation. Review carefully before running manually.
# ==============================================================================

set -euo pipefail

# 1. Refuse to run as root directly (use sudo for individual commands)
if [[ "${EUID}" -eq 0 ]]; then
    echo "Error: Do not run this script directly as root. Run as a normal user with sudo privileges." >&2
    exit 1
fi

# 2. Require confirmation environment variable
if [[ "${CONFIRM_RUN_LAB02:-}" != "true" ]]; then
    echo "Safety safeguard: CONFIRM_RUN_LAB02=true is not set."
    echo "To run this script manually in an isolated VM, execute:"
    echo "  export CONFIRM_RUN_LAB02=true"
    echo "  $0"
    exit 1
fi

# 3. Interactive confirmation prompt
echo "WARNING: This script will create system group 'lab02_web', service accounts 'lab02_deploy' and 'lab02_nginx',"
echo "and directory '/srv/lab02-app' using sudo."
read -r -p "Are you sure you want to proceed? Type 'yes' to continue: " RESPONSE
if [[ "${RESPONSE}" != "yes" ]]; then
    echo "Aborted by user."
    exit 0
fi

# 4. Abort if any target entity already exists
if getent group lab02_web >/dev/null 2>&1; then
    echo "Error: Group 'lab02_web' already exists. Aborting." >&2
    exit 1
fi

for u in lab02_deploy lab02_nginx; do
    if id "${u}" >/dev/null 2>&1; then
        echo "Error: User '${u}' already exists. Aborting." >&2
        exit 1
    fi
done

if [[ -e /srv/lab02-app ]]; then
    echo "Error: Directory '/srv/lab02-app' already exists. Aborting." >&2
    exit 1
fi

echo "--- Creating system group lab02_web ---"
sudo groupadd --system lab02_web

echo "--- Creating system users (nologin, locked password) ---"
sudo useradd --system --no-create-home --shell /usr/bin/nologin --gid lab02_web lab02_deploy
sudo useradd --system --no-create-home --shell /usr/bin/nologin --gid lab02_web lab02_nginx

echo "--- Provisioning /srv/lab02-app with setgid and group ownership ---"
sudo mkdir -p /srv/lab02-app
sudo chown lab02_deploy:lab02_web /srv/lab02-app
sudo chmod 2750 /srv/lab02-app

echo ""
echo "=== Lab 02 Users Setup Complete ==="
echo "Verification commands to run:"
echo "  id lab02_deploy"
echo "  id lab02_nginx"
echo "  ls -ld /srv/lab02-app"
if command -v namei >/dev/null 2>&1; then
    echo "  namei -l /srv/lab02-app"
fi
