# Dockerfile (production‑ready multi‑stage build)
# ARG for Python version – verify the exact tag from Docker Hub (e.g., 3.11) before building
ARG PYTHON_VERSION=3.11

# ---------- Builder stage ----------
FROM python:${PYTHON_VERSION}-slim AS builder
# Set a fixed UID/GID for the non‑root user that will run the app
ARG APP_UID=10001
ARG APP_GID=10001
RUN set -eux; \
    addgroup --gid $APP_GID appgroup && \
    adduser --uid $APP_UID --gid $APP_GID --disabled-password --gecos "" appuser

# Create a virtual environment in a known location
ENV VENV_PATH=/opt/venv
RUN python -m venv $VENV_PATH

# Copy only the pinned requirements file first to leverage Docker layer caching
COPY app/requirements.txt ${VENV_PATH}/requirements.txt
# Install dependencies into the virtual environment without cache to keep image small
RUN $VENV_PATH/bin/pip install --no-cache-dir -r ${VENV_PATH}/requirements.txt

# ---------- Final stage ----------
FROM python:${PYTHON_VERSION}-slim AS final
# Environment variables for Python runtime behavior
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH

# Copy the virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Set working directory and copy application source code with proper ownership
WORKDIR /app
COPY --chown=appuser:appgroup app/ /app/

# Create a non‑root user (matches builder UID/GID) – this user already exists in builder, but we ensure it exists here
USER appuser:appgroup

# Expose the Flask port
EXPOSE 8000

# OCI image metadata annotations
LABEL org.opencontainers.image.title="Day 07 Production‑Ready Flask App"
LABEL org.opencontainers.image.description="Multi‑stage build of a minimal Flask application for the 30‑days‑of‑devops series"
LABEL org.opencontainers.image.source="https://github.com/ahmadjawad533/30-days-0f-devops"

# Healthcheck – uses Python stdlib to query the /health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request, sys; \
    resp = urllib.request.urlopen('http://127.0.0.1:8000/health'); \
    sys.exit(0 if resp.status == 200 else 1)"

# Entrypoint runs Gunicorn in exec form for proper signal handling
ENTRYPOINT ["gunicorn", "-w", "2", "-b", "0.0.0.0:8000", "app:app", "--access-logfile", "-", "--error-logfile", "-"]
