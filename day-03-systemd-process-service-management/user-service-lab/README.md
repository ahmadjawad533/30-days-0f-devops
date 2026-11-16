# systemd User Service Hands-On Lab

> [!NOTE]
> **Safety and Isolation Statement:**
> - `run-user-lab.sh` operates entirely in unprivileged user space (`~/.config/systemd/user`).
> - **No `sudo` is required or used.**
> - User services run under your personal systemd user manager instance (`systemd --user`).
> - Nothing in this lab enables user session lingering (`loginctl enable-linger`).
> - Strictly touches files prefixed with `lab03-`.
> - **Review the scripts line by line before running them. Run cleanup afterwards.**

---

## Lab Overview

This lab walks through managing services without administrative privileges using systemd's built-in user instance:
1. **Unit Installation:** Deploys `lab03-heartbeat.service` under `~/.config/systemd/user/`.
2. **State & Property Inspection:** Explores `systemctl --user status`, `systemctl --user show`, and `journalctl --user`.
3. **Resilience & Auto-Restart:** Uses `systemctl --user kill -s KILL` to simulate a crash, observing systemd's automatic recovery via `Restart=on-failure` and `NRestarts` counter tracking.
4. **Drop-In Overrides:** Demonstrates customizing settings (e.g. `RestartSec=5` and `NoNewPrivileges=yes`) using drop-in files (`.d/override.conf`) without editing original unit files.
5. **Crash Diagnostics:** Starts `lab03-broken.service` to inspect real systemd error reporting (status `203/EXEC`).
6. **Teardown:** Cleans up all units cleanly.

---

## How to Run (Author/Student Manual Execution)

To run the user-service lab manually on your workstation:

```bash
cd day-03-systemd-process-service-management/user-service-lab
export CONFIRM_RUN_LAB03=true
./run-user-lab.sh
```

To clean up manually at any time:
```bash
./cleanup-user-lab.sh
```
