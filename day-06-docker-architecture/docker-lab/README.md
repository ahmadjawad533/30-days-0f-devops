# Docker Lab (Day 06)

This directory contains **write‑only** scripts that demonstrate Docker’s architecture for Day 06. They never run automatically; you must execute them yourself.

## Safety notes
- All Docker commands target containers whose names start with `lab06-` and carry the label `project=30days-lab06`.
- No `docker prune` or wildcard removal is performed.
- The scripts only run `docker --version` to verify the client is available; they never modify the host system other than creating/removing the lab containers and the `alpine` image (only if it was not present before the lab).
- Ports, mounts, and privileged options are **not** used.

## Running the lab
1. (Optional) Export `DOCKER_LAB_CONFIRM=yes` and set `DOCKER_LAB_CONFIRM_INPUT=yes` in your shell before running the script to bypass the manual confirmation prompt.
2. Execute:
   ```bash
   ./run-docker-lab.sh
   ```
   The script will record its output in `../outputs/` files.
3. When finished, clean up:
   ```bash
   ./cleanup-docker-lab.sh
   ```

**Review the scripts line‑by‑line before running them.**

---
*The Docker daemon must be running on your machine. See the official Docker installation guide for your platform.*
