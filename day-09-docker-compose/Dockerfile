FROM python:${PYTHON_VERSION:-3.11}-slim

# Create a non‑root user (UID 1000) and set working directory
ARG USER_ID=1000
RUN addgroup --gid $USER_ID appuser && \
    adduser --uid $USER_ID --gid $USER_ID --disabled-password --gecos "" appuser

WORKDIR /app
COPY app/requirements.in .
# Install build dependencies only for compilation, then remove them
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.in && \
    rm -rf /root/.cache

COPY app/ .

# Use a non‑root user to run the app
USER appuser

# Healthcheck using the Flask health endpoint
HEALTHCHECK --interval=10s --timeout=3s \
  CMD curl -f http://localhost:8000/health || exit 1

# Default command runs via gunicorn (as defined in compose.yaml)
CMD ["gunicorn", "-b", "0.0.0.0:8000", "app:app"]
