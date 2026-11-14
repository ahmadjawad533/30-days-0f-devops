# Day 01: Linux Architecture Explained: What Every DevOps Engineer Should Know

Article: [link TBD]

Welcome to Day 01 of the **30 Days of DevOps** series. Before automating cloud deployments or containerizing microservices, every DevOps and Cloud engineer must understand how Linux operates beneath the abstractions. This lab provides hands-on inspection scripts to observe the real kernel, process hierarchy, memory management, virtual filesystems, and the system call interface on your running host.

---

## Purpose

The objective of Day 01 is to bridge theoretical OS concepts with practical command-line inspection:
- Differentiate between **User Space** (unprivileged Ring 3) and **Kernel Space** (privileged Ring 0).
- Understand how user applications interact with the kernel through the **System Call Interface (SCI)**.
- Explore how Linux uses pseudo-filesystems (`/proc` and `/sys`) to represent kernel data structures as regular files.
- Inspect foundational container building blocks: **Namespaces**, **Control Groups (cgroups)**, and **File Descriptors**.

---

## Architecture Reference

A visual diagram illustrating user space, the system call interface, kernel subsystems, and hardware can be found at:
- [docs/layered-architecture.md](docs/layered-architecture.md) (features a Mermaid diagram with an ASCII text fallback).

---

## Safety Statement

This inspection lab is strictly **read-only**:
- **Zero system alterations:** No packages are installed or removed, no `sudo` commands are issued, no `sysctl` configurations are modified, and no kernel modules are loaded or unloaded.
- **Zero process disruption:** No processes are terminated or modified.
- **Privacy protection:** Does not read private files (`~/.ssh`, `~/.aws`, `~/.config`, `/etc/shadow`, shell history), environment variables, or `/proc/*/environ`.
- **Cloud safety:** Does not interact with any AWS resources or credentials.

---

## Prerequisites

Standard Linux core utilities found on modern Linux distributions:
- `bash` (version 4.0+)
- `coreutils` (`cat`, `uname`, `cut`, `sort`, `uniq`, `head`, `mktemp`, `rm`, `ls`)
- `procps` (`ps`, `free`)
- `util-linux` (`findmnt`, `ulimit`)
- Optional tools:
  - `strace` (used to demonstrate real-time system call tracing; if missing, section 10 gracefully skips without failing).
  - `pstree` (from `psmisc`; if missing, section 02 skips the tree view gracefully).

---

## How to Run

1. Navigate to the `day-01-linux-architecture` directory:
   ```bash
   cd day-01-linux-architecture
   ```
2. Make the script executable:
   ```bash
   chmod +x inspect.sh
   ```
3. Execute the script:
   ```bash
   ./inspect.sh
   ```

Running the script will print a section-by-section summary to standard output and generate structured log files inside the `outputs/` directory. The script is idempotent; running it again overwrites `outputs/` cleanly.

---

## Inspection Script Breakdown

| Section | Command(s) Executed | What It Shows | Linux Architecture Concept |
| :---: | :--- | :--- | :--- |
| **01** | `uname -r; uname -m; cat /etc/os-release` | Active Linux kernel release, CPU hardware architecture, and OS distribution identity. | **Kernel & OS Identification**: Establishes the running kernel build and architecture (User vs Kernel base). |
| **02** | `cat /proc/1/comm; ps -o pid,ppid,stat,comm -p 1,$$; pstree -p $$` | The system's root initialization process (PID 1) and process hierarchy leading to the running shell. | **PID 1 & Process Tree**: Explores the process life cycle, parent-child relationships, and PID 1 responsibility. |
| **03** | `ps -eo stat --no-headers \| cut -c1 \| sort \| uniq -c` | Aggregate count of all processes across process states (Sleeping, Running, Disk sleep, Zombie, Idle). | **Process States & Scheduling**: Demonstrates task states in the Linux scheduler queue. |
| **04** | `free -h; grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree):' /proc/meminfo` | System memory allocation, buffers, active caches, available RAM, and swap space. | **Memory Management Subsystem**: Demonstrates physical vs virtual memory, page caching, and kernel memory reporting. |
| **05** | `lsmod \| head -n 15` | Dynamically loaded kernel modules currently resident in kernel memory. | **Kernel Modules & Extensibility**: Demonstrates monolithic kernel modularity vs in-tree compiled drivers. |
| **06** | `ls /proc/self \| head -n 20; ls /sys/class \| head -n 20; findmnt -t proc,sysfs,devtmpfs,cgroup2` | Runtime structures in the process information pseudo-fs (`/proc`), device subsystem (`/sys`), and mounted VFS filesystems. | **Pseudo-Filesystems & VFS**: Explains the "everything is a file" abstraction and live memory inspection. |
| **07** | `ls -l /proc/self/fd; ulimit -n; ulimit -Hn` | Standard streams (0, 1, 2) open for the active process alongside soft and hard file descriptor limits. | **File Descriptors & Resource Limits**: I/O multiplexing foundation, kernel handle tables, and open-file ceiling. |
| **08** | `ls -l /proc/self/ns; cat /proc/self/cgroup` | Active namespace links (mnt, net, pid, user, uts, ipc) and cgroup membership slice. | **Namespaces & Cgroups**: The foundational kernel primitives powering Linux containers (Docker, containerd). |
| **09** | `cat /proc/loadavg` | Exponentially decaying average of runnable and uninterruptible tasks over 1, 5, and 15 minutes. | **CPU Load & Scheduler Dynamics**: System saturation metrics directly from the kernel scheduler. |
| **10** | `strace -f -e trace=openat,read,write,execve cat <file>` | Trace of exact system calls emitted by `cat` across the user-to-kernel boundary. | **System Call Interface (SCI)**: Observes the CPU context switch between Ring 3 (User) and Ring 0 (Kernel). |

---

## Before You Publish

> [!WARNING]
> Before committing or pushing your generated `outputs/` folder to a public repository:
> - Review all generated `.txt` files in `outputs/` to ensure no sensitive personal data (e.g. hostnames, internal IPs, usernames, or private path identifiers) are inadvertently exposed.
> - Replace sensitive values with standardized redactions such as `<redacted-hostname>` or `<redacted-user>`.
