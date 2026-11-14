# Linux Architecture: Layered Model

Understanding the boundary between user space and kernel space is fundamental for troubleshooting systems, diagnosing performance issues, and configuring containers and virtualization.

---

## Architecture Diagram (Mermaid)

```mermaid
flowchart TD
    subgraph Userspace ["User Space (Ring 3 / Unprivileged)"]
        direction TB
        Apps["User Applications & DevOps Utilities<br/>(bash, docker, git, nginx, python, inspect.sh)"]
        LibC["GNU C Library (glibc / musl)<br/>Standard System API & Wrappers"]
        Apps --> LibC
    end

    SysCallInterface["System Call Interface (SCI)<br/>(openat, read, write, execve, clone, mmap)"]
    LibC -->|Syscall / CPU Trap Instruction| SysCallInterface
    Apps -.->|Direct Syscall| SysCallInterface

    subgraph KernelSpace ["Kernel Space (Ring 0 / Privileged)"]
        direction TB
        SysCallInterface --> Subsystems

        subgraph Subsystems ["Core Kernel Subsystems"]
            direction LR
            ProcMgmt["Process Management<br/>(Scheduler, Namespaces, Cgroups)"]
            MemMgmt["Memory Management<br/>(Virtual Memory, Paging, Page Cache)"]
            VFS["Virtual File System (VFS)<br/>(ext4, btrfs, /proc, /sys, pipes)"]
            NetStack["Network Stack<br/>(TCP/IP, Netfilter, Sockets)"]
            DevDrivers["Device Drivers<br/>(Block, Character, Network)"]
        end
    end

    subgraph Hardware ["Hardware Layer"]
        direction LR
        CPU["CPU & MMU"]
        RAM["Physical RAM"]
        Storage["Storage (NVMe / SSD / HDD)"]
        NIC["Network Interface Card"]
    end

    Subsystems --> Hardware
```

---

## Architecture Diagram (ASCII Fallback)

```text
+=============================================================================+
|                                 USER SPACE                                  |
|                          (Unprivileged - Ring 3)                            |
|                                                                             |
|  +-----------------------------------------------------------------------+  |
|  | Applications, Daemons & Tools (bash, nginx, docker, python, inspect)  |  |
|  +-----------------------------------------------------------------------+  |
|                                      |                                      |
|                                      v                                      |
|  +-----------------------------------------------------------------------+  |
|  | C Standard Library (glibc / musl API wrappers)                        |  |
|  +-----------------------------------------------------------------------+  |
+=============================================================================+
                                       |
                                       | Syscall / CPU Trap Instruction
                                       v
+=============================================================================+
|                                KERNEL SPACE                                 |
|                           (Privileged - Ring 0)                             |
|                                                                             |
|  +-----------------------------------------------------------------------+  |
|  | System Call Interface (SCI): openat, read, write, clone, execve, etc.  |  |
|  +-----------------------------------------------------------------------+  |
|                                      |                                      |
|       +-------------------+----------+----------+-------------------+       |
|       |                   |                     |                   |       |
|       v                   v                     v                   v       |
|  +-------------+   +---------------+    +---------------+    +------------+ |
|  | Process &   |   | Memory        |    | Virtual File  |    | Network    | |
|  | Scheduling  |   | Management    |    | System (VFS)  |    | Stack      | |
|  | (cgroups,   |   | (Paging, MMU, |    | (ext4, btrfs, |    | (TCP/IP,   | |
|  | namespaces) |   | Swap)         |    | /proc, /sys)  |    | Netfilter) | |
|  +-------------+   +---------------+    +---------------+    +------------+ |
|       |                   |                     |                   |       |
|       +-------------------+----------+----------+-------------------+       |
|                                      |                                      |
|                                      v                                      |
|  +-----------------------------------------------------------------------+  |
|  | Device Drivers (Disk, Network, Display, Bus, Character, Block)       |  |
|  +-----------------------------------------------------------------------+  |
+=============================================================================+
                                       |
                                       v
+=============================================================================+
|                               HARDWARE LAYER                                |
|                  (CPU, Memory/MMU, Disks, Network Cards)                    |
+=============================================================================+
```

---

## Architectural Boundaries Explained

1. **User Space vs. Kernel Space**:
   - **User space** executes in unprivileged CPU ring (x86 Ring 3). Code running here cannot directly access hardware registers, physical devices, or raw kernel memory.
   - **Kernel space** executes in highest privilege (x86 Ring 0). The kernel manages core hardware, arbitrates access, and schedules processes.
2. **System Call Interface (SCI)**:
   - The strictly defined transition point between user programs and the kernel. An application issues an interrupt/syscall instruction to request system resources (reading files, dispatching network packets, spawning processes).
3. **Pseudo-Filesystems (`/proc` and `/sys`)**:
   - The Virtual File System (VFS) abstracts kernel internals as directory structures:
     - `/proc` exposes live process structures and system runtime state.
     - `/sys` exposes kernel device trees, buses, drivers, and class hierarchies.
