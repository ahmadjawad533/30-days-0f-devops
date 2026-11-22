# Day 09 – Docker Compose Multi‑Container Lab

## Overview
In this lab you will spin up a **Python Flask web service** and a **PostgreSQL** database using Docker Compose. The two containers will communicate over an internal Docker network, while the web service is exposed on your host at `127.0.0.1:18100`. All resources are labelled with `project=30days-lab09` and prefixed with `lab09-` to avoid collisions.

## Safety Rules (re‑iterated)
- **No privileged containers** – do not run with `--privileged` or `--cap-add`.
- **No host‑port exposure for the database** – the DB is only reachable from the `web` container.
- **All secrets are stored in a runtime‑generated `.env`** (ignored by Git). Only an `.env.example` with placeholder values is committed.
- **Docker daemon access is limited to version checks** (`docker --version`, `docker compose version`).
- **All services are labelled** `project=30days-lab09` and prefixed `lab09-`.
- **No firewall/iptables changes** – the lab runs entirely on localhost.

## Prerequisites
- Bash, Python 3, Docker, Docker Compose (client‑side only, version 2.x+).
- `curl`, `ss` and `git` are also used by helper scripts.

## Lab Layout (files created for this day)
```
day-09-docker-compose/
├─ app/
│  ├─ app.py          # Flask service + DB logic
│  └─ requirements.in # Runtime dependencies (flask, gunicorn, psycopg2‑binary)
├─ .dockerignore
├─ Dockerfile
├─ compose.yaml
├─ .env.example       # Placeholder values for secrets
├─ .gitignore         # Ignores .env and temporary artifacts
├─ static-checks.sh   # Linting & static analysis script
├─ pin-requirements.sh# Generates a pinned requirements.txt
├─ compose‑lab/
│  ├─ README.md       # Lab instructions (this file is a copy)
│  ├─ run-compose‑lab.sh    # Orchestrates the lab run
│  └─ cleanup-compose‑lab.sh# Tears down the lab safely
├─ docs/
│  └─ compose‑stack.md# Architecture diagram and command cheat‑sheet
└─ NOTES.md           # Personal notes template
```

## Order of Operations
1. **Read the lab description** – this README.
2. **Create a runtime `.env`** (or copy the example and fill in a strong password).
3. Run `./compose-lab/run-compose-lab.sh`. The script will:
   - Verify Docker/Docker‑Compose versions.
   - Ensure the host port `18100` is free.
   - Bring the stack up (`docker compose up -d`).
   - Wait for the health checks to pass.
   - Print the web service URL.
4. Test the service:
   ```bash
   curl http://127.0.0.1:18100/
   curl http://127.0.0.1:18100/health
   ```
5. When finished, run `./compose‑lab/cleanup-compose‑lab.sh` to bring everything down and remove generated secrets.

## Claim‑to‑Evidence Table
| # | Claim | Evidence Method |
|---|-------|-----------------|
| 1 | Flask web service is reachable on localhost on port **18100**. | `curl -f http://127.0.0.1:18100/` returns JSON with a `visits` field. |
| 2 | PostgreSQL container runs with the expected image and credentials. | `docker compose exec db pg_isready` passes (allowed as a version‑check only). |
| 3 | Healthcheck of the web service reports `status: ok`. | `curl -f http://127.0.0.1:18100/health` returns `{"status":"ok"}`. |
| 4 | The lab cleans up all resources without leaving orphan containers or volumes. | After `cleanup‑compose‑lab.sh` runs, `docker compose ps` shows no containers, `docker volume ls` shows no `lab09‑*` volumes. |

## Before Publishing
- Verify that **no** `.env` file is tracked by Git (`git status` should show it as untracked). The repository root already ignores `.env` globally.
- Run `./static-checks.sh` and ensure **all** checks pass – any failures must be fixed before PR.
- Update the root `README.md` table entry for Day 09 to `✅` and link to this folder.

---

**Happy hacking!** 🎉
