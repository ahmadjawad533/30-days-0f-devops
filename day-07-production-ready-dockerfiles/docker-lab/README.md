# Docker lab overview

This directory contains **write‑only** scripts that demonstrate a full Docker workflow for Day 07. They never run automatically; you must execute them yourself.

- **run-docker-lab.sh** – builds the naive and production images, tests caching, runs containers, collects health‑check data, and writes all output to `../outputs/`.
- **cleanup-docker-lab.sh** – safely removes only the containers and images that were created by the lab (label `project=30days-lab07`).

**Safety notes**
- Only containers/images with the `project=30days-lab07` label are touched.
- No `docker prune` or wildcard removals are performed.
- All published ports bind to `127.0.0.1` only.
- The scripts require `docker --version` to be available; they never modify your host system outside the repository.

**Workflow**
1. Run `pin-requirements.sh` to generate a pinned `requirements.txt`.
2. Review and commit `requirements.txt`.
3. Run `run-docker-lab.sh`.
4. After reviewing the generated output files in `../outputs/`, run `cleanup-docker-lab.sh`.

For more details on the multi‑stage Docker build, see `../docs/multi-stage-build.md`.
