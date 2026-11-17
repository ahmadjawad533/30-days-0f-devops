# systemd User Timer Automation Lab

> [!NOTE]
> **Safety and Isolation Statement:**
> - `run-timer-lab.sh` operates entirely in unprivileged user space (`~/.config/systemd/user`).
> - **No `sudo` is required or used.**
> - Timers and services run under your personal systemd user instance.
> - Nothing in this lab enables user session lingering (`loginctl enable-linger`).
> - Strictly touches files prefixed with `lab04-`.
> - **Review the scripts line by line before running them. Run cleanup afterwards.**

---

## Lab Overview

This lab demonstrates modern periodic task scheduling using native systemd timers instead of legacy cron jobs:
1. **Timer Definition:** Explores `lab04-backup.timer` configured with `OnCalendar=*:0/5` (triggers every 5 minutes).
2. **Oneshot Service:** Connects the timer to `lab04-backup.service`, which invokes `backup-rotate.sh` with strict workspace boundaries.
3. **Execution Monitoring:** Inspects `systemctl --user list-timers` to view countdowns and elapses.
4. **Structured Logging:** Uses `journalctl --user` to view execution output without managing custom log rotation configurations.
5. **Teardown:** Stops and removes timer and service files cleanly.

---

## How to Run (Author/Student Manual Execution)

To test the timer lab manually on your workstation:

```bash
cd day-04-bash-scripting-devops-automation/timer-lab
export CONFIRM_RUN_LAB04=true
./run-timer-lab.sh
```

To clean up manually at any time:
```bash
./cleanup-timer-lab.sh
```
