```mermaid
flowchart LR
    subgraph "lab09-network"
        db[lab09-db]
        web[lab09-web]
    end
    db -->|postgres://lab09:POSTGRES_PASSWORD@db:5432/lab09| web
    web -->|http://127.0.0.1:18100| Host
```

# Compose Stack Overview

- **Network**: `lab09-network` (bridge driver) isolates the two services.
- **Database (`lab09-db`)**:
  - Image: `${POSTGRES_IMAGE:-postgres:15-alpine}`
  - Persistent volume `lab09-db-data` mounted at `/var/lib/postgresql/data`.
  - Healthcheck uses `pg_isready` to ensure readiness before the web service starts.
  - No host ports are exposed; only reachable from the `web` service.
- **Web (`lab09-web`)**:
  - Built from the `Dockerfile` in this repository.
  - Exposes port `127.0.0.1:18100:8000` on the host for local access.
  - Depends on the `db` service health.
  - Uses `.env` for runtime configuration (DB credentials, etc.).

**Tip**: The `lab09-` prefix and `project=30days-lab09` label allow you to clean up resources safely with `docker compose down` or `docker ps --filter "label=project=30days-lab09"`.
