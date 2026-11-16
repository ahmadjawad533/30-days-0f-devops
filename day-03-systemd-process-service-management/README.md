# Day 03: Linux Process and Service Management with systemd

Article: [link TBD]

Welcome to Day 03 of the **30 Days of DevOps** series. Modern cloud engineering and container orchestration depend heavily on systemd and Linux process management concepts—from signal handling (graceful SIGTERM vs forceful SIGKILL) and control groups (cgroups) to service dependencies and automatic crash recovery. This lab explores real-world systemd inspection, unprivileged process signal experimentation, and user service management.

---

## Purpose

The objective of Day 03 is to provide a complete, practical mental model of:
- **PID 1 & systemd Architecture:** How systemd manages boot targets, dependencies, unit files, and security exposures.
- **POSIX Signals & Process Lifecycle:** How processes receive, catch, or succumb to signals (`SIGTERM`, `SIGKILL`, `SIGSTOP`, `SIGCONT`), and how exit statuses map to signals (`128 + signal`).
- **Process Priority & Niceness:** How Linux schedules tasks and how unprivileged users can raise niceness to yield CPU.
- **Zombie Process Lifecycle:** How child exit status retention causes defunct/zombie states until reaped by parents or adopted by PID 1.
- **systemd Unit Anatomy & Hardening:** How unit directives (`Type`, `ExecStart`, `Restart`, `RestartSec`, `NoNewPrivileges`) control daemon resilience.
- **Drop-In Overrides & Crash Codes:** How to extend service units cleanly with `.service.d/override.conf` and diagnose failures like `203/EXEC`.

---

## Safety Statement

- **`inspect-systemd.sh` is strictly read-only:** It never runs `sudo`, never modifies `/etc` or system unit files, and avoids unfiltered log or process table dumps.
- **`process-signals-lab.sh` is strictly project-local:** It runs unprivileged (no `sudo`) and creates temporary files solely inside a local `lab-workdir/` (which is removed cleanly upon exit). It signals **only** PIDs that the script itself spawned.
- **`user-service-lab/` is run ONLY by the human author/student:** Automation writes the templates and scripts but never executes `run-user-lab.sh` or `cleanup-user-lab.sh`. When run manually, it touches only files under `~/.config/systemd/user/` prefixed with `lab03-` without root privileges or session lingering.

---

## Prerequisites

Standard Linux core utilities found on modern Linux distributions:
- `bash` (version 4.0+)
- `coreutils` (`sleep`, `cat`, `awk`, `sort`, `uniq`, `head`, `date`, `kill`)
- `procps` (`ps`, `nice`, `renice`)
- `systemd` (`systemctl`, `systemd-analyze`, `journalctl`)
- Optional tools:
  - `python3` (used for the educational zombie process demo; if missing, the demo skips gracefully).

---

## How to Run

1. Navigate to the Day 03 directory:
   ```bash
   cd day-03-systemd-process-service-management
   ```
2. Make scripts executable:
   ```bash
   chmod +x inspect-systemd.sh process-signals-lab.sh
   ```
3. Run the read-only systemd inspector:
   ```bash
   ./inspect-systemd.sh
   ```
4. Run the process signals laboratory:
   ```bash
   ./process-signals-lab.sh
   ```

Both scripts are idempotent; re-running them cleanly overwrites files in `outputs/`.

---

## Lab Breakdown & Concepts Demonstrated

### Part 1: Read-Only systemd Inspection (`inspect-systemd.sh`)

| Section | Command(s) Executed | What It Shows | Linux Architecture & Admin Concept |
| :---: | :--- | :--- | :--- |
| **01** | `systemctl --version; cat /proc/1/comm` | systemd version build, features, and PID 1 confirmation. | **Init System & PID 1**: Confirms systemd is running as the root ancestor process. |
| **02** | `systemctl is-system-running; systemctl get-default` | Overall system operational health and default boot target. | **System States & Targets**: High-level system state (running/degraded) and target mapping (`multi-user.target` / `graphical.target`). |
| **03** | `systemctl list-units --type=service --state=running` | Top 15 active running services (unit names only). | **Service Units**: Active background daemons currently operating on the host. |
| **04** | `systemctl list-unit-files --type=service` | Aggregate distribution of unit file enablement states. | **Unit Enablement**: Differentiates between enabled (autostart on boot), disabled, static, and masked units. |
| **05** | `systemctl list-units --state=failed` | Listing of any services currently in a failed state. | **Fault Detection**: Quick identification of crashed or misconfigured system services. |
| **06** | `systemctl cat systemd-journald.service` | Full configuration file definitions including drop-ins. | **Unit Anatomy**: Direct view of `[Unit]`, `[Service]`, and `[Install]` sections. |
| **07** | `systemctl show systemd-journald.service` | Low-level internal property keys (`MainPID`, `ControlGroup`, `ActiveState`). | **systemd Property Bus**: Exposes how systemd tracks state and cgroups internally. |
| **08** | `systemctl list-dependencies default.target` | Hierarchical tree of units required by the default target. | **Dependency Graph**: Visualization of `Wants=`, `Requires=`, and `After=` ordering. |
| **09** | `systemd-analyze` | Time spent in kernel, initrd, and userspace during boot. | **Boot Performance**: Measuring startup latencies across operating phases. |
| **10** | `systemd-analyze security` | Automated security assessment scores across system units. | **Service Hardening & Sandboxing**: Auditing exposure levels against system isolation features. |
| **11** | `kill -l` | Table of all POSIX signal names and numbers supported by the kernel. | **Signals Reference**: Signal numeric mappings (`SIGTERM=15`, `SIGKILL=9`, `SIGSTOP=19`, `SIGCONT=18`). |
| **12** | `ps -o pid,ni,pri,stat,comm -p $$` | Priority and niceness (`NI`) of the current shell. | **CPU Scheduling Priority**: Process niceness scale (`-20` highest priority to `+19` lowest priority). |

### Part 2: Process Signals & States Lab (`process-signals-lab.sh`)

| Demo | What It Demonstrates | Linux Concept Explained |
| :---: | :--- | :--- |
| **A** | Background process launch and inspection via `ps`. | **Process Tracking**: Capturing child `$!` PID and inspecting state in process table. |
| **B** | Graceful termination via `SIGTERM` (Signal 15). | **Graceful Shutdown**: Process receives termination request; exits with status `143` (`128 + 15`). |
| **C** | Immediate termination via `SIGKILL` (Signal 9). | **Uncatchable Termination**: Kernel-level immediate execution halt; exits with status `137` (`128 + 9`). |
| **D** | Signal trapping (`trap` on `TERM` vs `KILL`). | **Signal Handlers**: Demonstrates that user code can catch and intercept `SIGTERM`, but `SIGKILL` cannot be caught or ignored. |
| **E** | Process suspension (`SIGSTOP`) and resumption (`SIGCONT`). | **Job Control**: Toggling between stopped state (`T`) and runnable sleeping state (`S`). |
| **F** | Priority adjustment via `renice` (`5` &rarr; `10`). | **Unprivileged Niceness**: Demonstrates that regular users can increase niceness (yield CPU priority) without root permissions. |
| **G** | Zombie process creation and reaping upon parent death. | **Zombie State (`Z`)**: How an exited child process remains in the process table until its exit code is read by parent `wait()` or reaped by PID 1. |

---

## Architectural Reference Diagrams

Visual diagrams illustrating state transitions and the two-stage `SIGTERM`-then-`SIGKILL` stop sequence can be found at:
- [docs/service-lifecycle.md](docs/service-lifecycle.md) (features a Mermaid diagram with an ASCII fallback).

---

## Optional User-Service Lab (`user-service-lab/`)

For learners who wish to test unprivileged systemd user services, drop-in overrides, and crash recovery:
- Review the guide at [user-service-lab/README.md](user-service-lab/README.md).

---

## Before You Publish

> [!WARNING]
> Before committing or pushing your generated `outputs/` folder to a public repository:
> - Review all generated `.txt` files in `outputs/` to ensure no sensitive personal data (e.g. hostnames, usernames, or private paths) are inadvertently exposed.
> - Replace sensitive values with standardized redactions such as `<redacted-username>` or `<redacted-hostname>`.
