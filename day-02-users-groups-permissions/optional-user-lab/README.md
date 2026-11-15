# Optional User and Sudoers Lab

> [!CAUTION]
> **PROMINENT WARNING: SYSTEM ACCOUNT AND SUDOERS MODIFICATIONS**
>
> The scripts in this folder (`setup-lab-users.sh`, `cleanup-lab-users.sh`, and `sudoers-lab02-deploy.example`) modify real system accounts, system groups, `/srv/`, and `/etc/sudoers.d/`.
> - **Never run these scripts on a production server or critical workstation without review.**
> - **We strongly recommend running this optional exercise inside a disposable virtual machine or isolated container.**
> - **Lockout Risk Warning:** Any misconfiguration in sudoers rules can lock your user out of administrative access.
> - **Review the scripts line by line before running them. Run cleanup afterwards.**

---

## What This Optional Lab Simulates

This lab demonstrates how real-world multi-user services and deployment automation pipelines should be provisioned:
1. **Service Accounts:** Creates non-interactive system users (`lab02_deploy` and `lab02_nginx`) with `nologin` shells and no interactive passwords.
2. **Shared Application Group:** Creates `lab02_web` and adds both service accounts to it.
3. **Setgid Shared Directory:** Prepares `/srv/lab02-app` with mode `2750` so deployment files automatically inherit group ownership.
4. **Least-Privilege Sudoers:** Provides an example rule allowing `lab02_deploy` to run exactly one specific, harmless maintenance command (`systemctl status lab02-demo.service`) without wildcards or broad root power.

---

## Manual Execution Instructions

If and only if you choose to test this in a disposable VM:

1. **Setup:**
   ```bash
   cd optional-user-lab
   export CONFIRM_RUN_LAB02=true
   ./setup-lab-users.sh
   ```
2. **Review & Test:**
   Inspect the created users, groups, and permissions according to the instructions output by the setup script.
3. **Cleanup:**
   ```bash
   ./cleanup-lab-users.sh
   ```
