# systemd Service Lifecycle and Process Management

Understanding how systemd transitions services across states and terminates processes is essential for designing resilient microservices, writing production-grade unit files, and diagnosing deployment timeouts or zombie processes.

---

## Service Lifecycle State Transitions

A systemd service moves through defined active and sub-states managed by its control group (cgroup) and process exit codes:

```mermaid
stateDiagram-v2
    [*] --> Inactive: Initial / stopped
    Inactive --> Activating: systemctl start / ExecStartPre
    Activating --> Active_Running: ExecStart succeeds (Type=simple/exec)
    Activating --> Failed: ExecStart exits non-zero / binary missing
    Active_Running --> Deactivating: systemctl stop / restart / kill
    Active_Running --> Failed: Process crashes with non-zero exit
    Active_Running --> Inactive: Clean process exit (exit code 0)
    Failed --> AutoRestart: Restart=on-failure (RestartSec timer)
    AutoRestart --> Activating: Timer expires
    Deactivating --> Inactive: Stop path finishes (SIGTERM or SIGKILL)
    Deactivating --> Failed: TimeoutSec exceeded / stop failure
```

---

## The Two-Stage Stop Path: SIGTERM to SIGKILL

When systemd stops a service (or during shutdown/restart), it executes a standardized, graceful-then-forceful two-stage teardown:

```mermaid
flowchart TD
    StopReq["Stop Request Issued<br/>(systemctl stop / SIGPWR / system reboot)"] --> ExecStopCheck{"Is ExecStop=<br/>configured?"}
    
    ExecStopCheck -- Yes --> RunExecStop["Run ExecStop command(s)"]
    ExecStopCheck -- No --> SendSigterm
    RunExecStop --> SendSigterm

    SendSigterm["Send SIGTERM (Signal 15) to cgroup processes<br/>Start TimeoutStopSec timer (default 90s)"] --> WaitProcess{"Do processes exit<br/>within TimeoutStopSec?"}

    WaitProcess -- Yes --> CleanExit["Clean Termination<br/>State: inactive (dead)<br/>Status code: 0 or expected exit"]
    WaitProcess -- No --> SendSigkill["Send SIGKILL (Signal 9) to entire cgroup<br/>(Cannot be caught or ignored)"]

    SendSigkill --> FinalCheck{"Processes reaped<br/>by kernel?"}
    FinalCheck -- Yes --> ForceKilled["Force Terminated<br/>State: failed / inactive<br/>cgroup cleaned up"]
```

---

## ASCII Fallback Diagram

```text
+=============================================================================+
|                      systemd SERVICE STOP & KILL PATH                       |
+=============================================================================+
                                       |
                                       v
                 +-------------------------------------------+
                 | Stop triggered: systemctl stop <unit>     |
                 +-------------------------------------------+
                                       |
                                       v
                 +-------------------------------------------+
                 | Send SIGTERM (Signal 15) to main PID /    |
                 | all processes inside the unit's cgroup    |
                 | Start TimeoutStopSec timer (e.g., 90s)    |
                 +-------------------------------------------+
                                       |
                   +-------------------+-------------------+
                   |                                       |
         [Process exits within timer]             [Timer expires: timeout]
                   |                                       |
                   v                                       v
     +---------------------------+           +---------------------------+
     | Clean Termination         |           | Send SIGKILL (Signal 9)   |
     | Unit state: inactive      |           | Kernels destroys process  |
     | cgroup cleanly deleted    |           | Unit state: failed/stop   |
     +---------------------------+           +---------------------------+
```

---

## Architectural Principles of systemd Process Tracking

1. **CGroup Tracking (No Escaping via Double Fork):**
   - Traditional init scripts tracked services via PID files (`/var/run/app.pid`). If a rogue daemon or worker fork-bombed or double-forked, orphaned processes escaped init tracking.
   - systemd places every service into its own dedicated control group slice (e.g. `/sys/fs/cgroup/system.slice/myservice.service`). When systemd signals or stops the service, it signals **every PID registered within that cgroup**, preventing orphaned daemon leakage.

2. **Signal Handling Differences:**
   - **SIGTERM (15):** Cooperative graceful shutdown. Handlers catch SIGTERM to close sockets, flush transaction buffers, complete active requests, and write checkpoints.
   - **SIGKILL (9):** Uncatchable kernel-level execution termination. The kernel immediately frees process address space, file descriptors, and CPU allocations.

3. **Restart Policies:**
   - `Restart=no`: Service is never restarted automatically.
   - `Restart=on-failure`: Service restarts if it terminates abnormally (non-zero exit status, fatal signal like SIGKILL/SIGSEGV, or watchdog timeout). Does not restart on clean exit (`exit 0`).
   - `Restart=always`: Re-executes regardless of whether the exit was clean or caused by an unhandled error.
