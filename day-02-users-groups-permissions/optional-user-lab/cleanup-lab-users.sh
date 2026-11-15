#!/usr/bin/env bash
# ==============================================================================
# cleanup-lab-users.sh - Clean up Lab 02 Entities
# Part of "30 Days of DevOps" by Ahmad Jawad Bandesha
#
# SAFETY NOTICE:
# Strictly guarded to clean up ONLY entities with the prefix "lab02_".
# It MUST NOT be run by automation. Review carefully before running manually.
# ==============================================================================

set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
    echo "Error: Do not run directly as root. Run as normal user with sudo." >&2
    exit 1
fi

echo "WARNING: This will remove lab02_deploy, lab02_nginx, group lab02_web, and /srv/lab02-app."
read -r -p "Are you sure you want to clean up? Type 'yes' to proceed: " CONFIRM
if [[ "${CONFIRM}" != "yes" ]]; then
    echo "Cleanup aborted."
    exit 0
fi

# Guarded user removal (lab02_ prefix check)
for u in lab02_deploy lab02_nginx; do
    if [[ "${u}" =~ ^lab02_ ]] && id "${u}" >/dev/null 2>&1; then
        echo "Removing user ${u}..."
        sudo userdel "${u}" || true
    fi
done

# Guarded group removal
if getent group lab02_web >/dev/null 2>&1; then
    echo "Removing group lab02_web..."
    sudo groupdel lab02_web || true
fi

# Guarded directory removal
if [[ -d /srv/lab02-app && "/srv/lab02-app" =~ ^/srv/lab02_? ]]; then
    echo "Removing /srv/lab02-app..."
    sudo rm -rf /srv/lab02-app || true
fi

# Guarded sudoers removal if user manually copied it
if [[ -f /etc/sudoers.d/lab02-deploy ]]; then
    echo "Removing /etc/sudoers.d/lab02-deploy..."
    sudo rm -f /etc/sudoers.d/lab02-deploy || true
fi

echo "=== Lab 02 Cleanup Finished ==="
