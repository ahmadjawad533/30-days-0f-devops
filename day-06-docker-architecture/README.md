# Docker Architecture Lab (Day 06)

## Overview
This lab demonstrates Docker's architecture, including the image format, layered filesystem, container creation, and how containers share the host kernel. It also shows how Docker interacts with the Linux kernel via namespaces and cgroups.

## Safety Statement
- The `namespaces-without-docker.sh` script uses **only Linux kernel namespaces** and does **not** require Docker or any elevated privileges.
- The Docker lab scripts (`run-docker-lab.sh` and `cleanup-docker-lab.sh`) are **write‑only**; they are never executed by the automation. When you run them, they will only affect containers whose names start with `lab06-` and carry the label `project=30days-lab06`.
- No Docker prune, wild‑card removals, or privileged operations are performed.

## Prerequisites
- `bash` (>=4)
- `unshare` (util‑linux)
- `ip` (iproute2)
- Docker Engine (daemon running) – required only for the Docker lab scripts, not for the namespace demo.

## How to Run
1. **Namespace demo** – generate real output:
   ```bash
   ./namespaces-without-docker.sh
   ```
   Outputs are written to the `outputs/` directory.
2. **Docker lab** – review the scripts before executing them:
   ```bash
   ./docker-lab/run-docker-lab.sh   # reads host Docker daemon, creates lab06 containers
   ./docker-lab/cleanup-docker-lab.sh   # removes only lab06 containers and optionally the image
   ```
   See `docker-lab/README.md` for detailed instructions.

## Demo Table
| Demo | Shows | Concept |
|------|-------|---------|
| 01 Host baseline | `id -u`, `hostname`, namespace links | Baseline host context |
| 02 User namespace | `unshare --user --map-root-user …` | User namespace mapping |
| 03 PID namespace | `unshare --pid … ps` | PID 1 inside a namespace |
| 04 UTS namespace | `unshare --uts … hostname` | Hostname isolation |
| 05 Network namespace | `unshare --net … ip link` | Isolated network stack |
| 06 Namespace comparison | compare host vs ns links | Differences across namespaces |
| 07 Not a container note | explanatory text | Kernel namespaces only |
| 08 Docker client/server | `docker version` (selected fields) | Docker client‑server model |
| 09 Docker image layers | `docker pull alpine`, `docker history` | Layered filesystem |
| 10 Shared kernel | `docker run … uname -r` vs host | Same kernel across containers |
| 11 Container as a process | `docker run -d …` + host PID inspection | Container ↔ host PID relationship |
| 12 Writable layer | `docker exec … echo …` then `docker diff` | Writable layer changes |
| 13 Resource limits | `docker run –memory=64m …` then cgroup check | Memory cgroup limits |
| 14 Stop behaviour | `docker stop` timings with/without `--init` | PID 1 handling |
| 15 Disk summary | `docker system df` (read‑only) | Disk usage overview |
| 16 Cleanup | `cleanup-docker-lab.sh` | Safe removal of lab resources |

## Before You Publish
- Review all files in `outputs/` for any personal data (username, hostname, absolute paths). Redact as needed before committing.
- Ensure the Docker lab scripts contain the required safety guards.

## Further Reading
- [Docker run path documentation](docs/docker-run-path.md)

---
*All commands in this lab are executed in a temporary `lab-workdir` and do not affect your system outside the repository.*
