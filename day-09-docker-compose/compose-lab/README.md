# Lab Instructions

This folder contains helper scripts to run and clean up the Docker Compose lab for Day 09.

- **`run-compose-lab.sh`** – Verifies Docker/Docker‑Compose versions, ensures the required host port is free, checks that a `.env` file exists (or creates one from `.env.example`), brings the stack up with `docker compose up -d`, waits for the healthchecks to pass, and prints the web service URL.
- **`cleanup-compose-lab.sh`** – Safely tears down the stack (`docker compose down -v --remove-orphans`), removes any generated `.env` file, and deletes temporary artefacts.

Both scripts are deliberately written to use only *client‑side* Docker commands (`docker --version` and `docker compose version`) for safety. The actual compose actions are performed **only when you run the scripts yourself**.
