# Day 07 – Production‑Ready Dockerfile Lab

**Purpose** – Build a minimal Flask web service, learn multi‑stage Docker builds, pin dependencies, and operate a safe Docker lab.

**Safety** – All scripts are write‑only; only `docker --version` is run. No `sudo`, no privileged Docker commands, and all containers/images are labelled `project=30days-lab07`.

**Prerequisites** – `bash`, `python3` (with `venv`), `curl`, Docker Engine (client only), optional `hadolint` and `shellcheck`.

### How to run
```bash
# 1️⃣ Static checks (no Docker)
./day-07-production-ready-dockerfiles/static-checks.sh

# 2️⃣ Pin Python requirements (write‑only script, run yourself)
./day-07-production-ready-dockerfiles/pin-requirements.sh

# 3️⃣ Review and commit the generated requirements.txt

# 4️⃣ Docker lab (write‑only scripts, run yourself)
./day-07-production-ready-dockerfiles/docker-lab/run-docker-lab.sh
```

The scripts generate output files under `outputs/`; review them before committing.

### Before you publish
> Inspect every file in `outputs/` for personal data (usernames, hostnames, absolute paths) and redact as needed.
