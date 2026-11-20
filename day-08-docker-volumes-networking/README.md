# Day 08 – Docker Volumes and Networking

## Lab Overview
This lab demonstrates creating Docker **volumes**, attaching them to containers, and configuring container networking using a user‑defined bridge network.

All Docker commands are **write‑only** – they will not be executed by the automation. You will run the scripts locally.

---

## Safety Rules
- All Docker objects must start with the prefix `lab08-` (e.g. `lab08-vol-data`, `lab08-net`).
- Images are based on `alpine:latest` (official image, includes `busybox` utilities). Verify the image name in the Dockerfile.
- Containers must be started with the label `project=30days-lab08` and publish ports bound to `127.0.0.1` only (e.g. `-p 127.0.0.1:18090:80`).
- **Never** use `docker rm -f`, `docker rmi -f`, `docker volume prune`, `docker network prune`, or any firewall/iptables commands.
- Only `docker --version` may be invoked by automation.

---

## Prerequisites
- Docker client (`docker --version` already verified).
- `bash`, `unshare`, `ip`, `nsenter` are available for the optional host‑network inspection script.

---

## Lab Steps
1. **Create a persistent volume** – `lab08-vol-data`.
2. **Create a user‑defined bridge network** – `lab08-net`.
3. **Run a web server container** using the volume and network, publishing on `127.0.0.1:18090`.
4. **Inspect the host network** – run `inspect-host-network.sh` (writes to `outputs/02-network-info.txt`).
5. **Static checks** – run `static-checks.sh` (writes to `outputs/03-static-check.txt`).
6. **Cleanup** – `cleanup-docker-lab.sh` removes only the objects created by this lab (prefixed names, label check).

---

## Outputs
All scripts create timestamped output files in the `outputs/` directory. After you run the lab locally, review the files and perform the required redaction scan before committing.

---

## Checklist before PR
- [ ] Verify Docker commands respect the `lab08-` prefix and label.
- [ ] Ensure published ports bind to `127.0.0.1`.
- [ ] Run `bash -n` on all scripts.
- [ ] Run `inspect-host-network.sh` to generate real output.
- [ ] Scan `outputs/` for personal data and redact if needed.
- [ ] Add a row for Day 08 in the root README (will be done automatically).

---

## References
- Docker volumes: https://docs.docker.com/storage/volumes/
- Docker bridge networks: https://docs.docker.com/network/bridge/
