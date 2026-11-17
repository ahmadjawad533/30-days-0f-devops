# Day 04: Bash Scripting for DevOps: Automating Everyday Linux Tasks

Article: [link TBD]

Welcome to Day 04 of the **30 Days of DevOps** series. Shell scripting is the primary glue of cloud automation, CI/CD runners, container entrypoints, and system administration. However, unhardened Bash scripts risk catastrophic data loss, concurrency races, and silent pipeline failures. This lab presents production-grade automation patterns: strict error trapping (`set -uo pipefail`), non-blocking file locking (`flock`), atomic archive creation, safe retention rotation, input validation, and systemd user timers.

---

## Purpose

The objective of Day 04 is to move from ad-hoc command execution to robust, production-ready DevOps automation:
- **Defensive Shell Configuration:** Understanding why blind `set -e` is risky and how `set -uo pipefail` combined with structured `log()`, `die()`, and cleanup `trap` patterns prevents failures.
- **Defensive Path Guards:** Protecting deletion and rotation routines by enforcing canonical `realpath` checks that strictly forbid `/`, `$HOME`, or out-of-boundary paths.
- **Atomic Operations & Integrity Verification:** Creating archives via `mktemp` scratch files, verifying them with `tar -tzf`, and promoting them atomically with `mv`.
- **Concurrency Locking:** Using kernel-level non-blocking `flock` to guarantee single-instance execution in cron/timer workflows.
- **Safe Retention Policies:** Rotating backups by strictly matching regex file patterns rather than blind globbing.
- **Health & Readiness Inspection:** Probing CPU load, memory availability, disk thresholds, listening ports, and systemd units with structured exit codes.

---

## Safety Statement

- **`health-check.sh` is strictly read-only:** It queries system state (`df`, `/proc/meminfo`, `/proc/loadavg`, `ss -ltn`) without mutating configuration or printing private process names.
- **`backup-rotate.sh` is strictly workspace-scoped:** It enforces path guards restricting operations exclusively to `./lab-workdir/` inside this lab folder. It supports dry-run mode (`-n`) and requires explicit flags.
- **`run-demo.sh` operates entirely unprivileged (no `sudo`):** All temporary files and test archives are quarantined inside `./lab-workdir/` and cleaned up automatically upon exit via trap.
- **`timer-lab/` is NEVER executed by automation:** The timer scripts modify only `~/.config/systemd/user/` and are reserved strictly for manual student experimentation.

---

## Prerequisites

Standard Linux core utilities found on modern Linux distributions:
- `bash` (version 4.0+)
- `coreutils` (`df`, `mktemp`, `rm`, `mv`, `cat`, `date`, `cut`, `awk`, `sort`, `uniq`, `find`)
- `tar`
- `util-linux` (`flock`, `realpath`)
- `iproute2` (`ss`)
- `systemd` (`systemctl`, `systemd-analyze`)
- Optional tools:
  - `shellcheck` (for static analysis; if missing, the step skips gracefully).

---

## Script Specifications & Exit Code Reference

### 1. `health-check.sh` Exit Codes
| Exit Code | Meaning | Condition |
| :---: | :--- | :--- |
| **0** | **OK** | All metrics (disk, memory, CPU load, failed units, TCP port) within normal thresholds. |
| **1** | **WARNING** | At least one metric exceeded its warning threshold (e.g. disk >= 80%, memory <= 20%, failed units > 0, port not listening). |
| **2** | **CRITICAL** | At least one metric exceeded critical threshold (metric >= 2x warning threshold or disk >= 95%). |
| **3** | **USAGE ERROR** | Invalid command-line options, missing arguments, or non-existent path. |

### 2. `backup-rotate.sh` Exit Codes
| Exit Code | Meaning | Condition |
| :---: | :--- | :--- |
| **0** | **SUCCESS** | Archive created, verified, atomically promoted, and retention rotation completed. |
| **3** | **PATH / USAGE ERROR** | Invalid options, missing arguments, or target path failed security workspace boundaries. |
| **4** | **LOCK CONTENTION** | Another instance is currently executing (`flock -n` failed). |
| **5** | **ARCHIVE FAILURE** | `tar -czf` creation failed or `tar -tzf` integrity check detected a corrupted archive. |

---

## How to Run the Demonstration Lab

1. Navigate to the Day 04 directory:
   ```bash
   cd day-04-bash-scripting-devops-automation
   ```
2. Make scripts executable:
   ```bash
   chmod +x run-demo.sh scripts/*.sh unsafe-examples/fixed-cleanup.sh timer-lab/*.sh
   ```
3. Run the demonstration harness:
   ```bash
   ./run-demo.sh
   ```

All test outputs will be generated in `outputs/`. The script is idempotent; re-running it cleanly overwrites previous logs.

---

## Demonstration Breakdown

| Demo | What It Demonstrates | DevOps & Bash Concept Explained |
| :---: | :--- | :--- |
| **01** | `bash -n` syntax check on all scripts & ShellCheck status. | **Syntax & Static Analysis**: Ensuring scripts parse cleanly before deployment. |
| **02** | `health-check.sh` under normal vs forced threshold breaches (`-d 1`). | **Structured Exit Codes**: Providing predictable status codes for monitoring agents. |
| **03** | Preparing test directory with spaces in filenames (`audit log 2026.txt`). | **Word-Splitting Resilience**: Ensuring filenames with whitespace do not break scripts. |
| **04** | `backup-rotate.sh -n` (Dry-run mode). | **Safe Pre-Flight**: Logging planned filesystem actions without modifying state. |
| **05** | 5 successive backup runs with `-k 3`. | **Safe Rotation**: Removing only the oldest archives matching strict regex patterns. |
| **06** | `tar -tzf` integrity verification. | **Verification Before Promotion**: Guaranteeing archives are non-empty and readable. |
| **07** | Path guards refusing missing dirs, `/etc`, empty `-s`, and `-k 0`. | **Defensive Path Validation**: Canonical realpath verification preventing escapes. |
| **08** | Concurrency test with background `flock`. | **Single-Instance Execution**: Preventing race conditions and server overloading. |
| **09** | SIGTERM simulation during active backup. | **Trap Cleanup**: Ensuring incomplete scratch archives are immediately destroyed upon interrupt. |
| **10** | `fixed-cleanup.sh` dry-run, real deletion, and path guard refusal. | **Remediating Shell Flaws**: Implementing parameter guards `${VAR:?}` and canonical path boundaries. |
| **11** | `script-template.sh` skeleton validation. | **Production Template**: Reusable base for engineering automation tools. |

---

## Reference Architecture & Control Flow

Detailed control-flow diagrams and a comparison table of shell safety options (`set -e`, `set -u`, `pipefail`) can be found at:
- [docs/backup-flow.md](docs/backup-flow.md) (features a Mermaid diagram with an ASCII fallback).

---

## Optional Timer Lab (`timer-lab/`)

For learners who wish to schedule backups periodically using systemd user timers instead of legacy cron jobs:
- Review the guide at [timer-lab/README.md](timer-lab/README.md).

---

## Before You Publish

> [!WARNING]
> Before committing or pushing your generated `outputs/` folder to a public repository:
> - Review all generated `.txt` files in `outputs/` to ensure no sensitive personal data (e.g. hostnames, usernames, or absolute home paths) are inadvertently exposed.
> - Replace sensitive values with standardized redactions such as `<redacted-username>` or `<redacted-hostname>`.
