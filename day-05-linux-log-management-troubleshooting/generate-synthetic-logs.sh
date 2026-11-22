#!/usr/bin/env bash
set -u

# Deterministic synthetic log generator for Day 05
# Uses Python 3 if available, otherwise Bash (limited).

LABDIR="$(pwd)/lab-workdir"
LOGDIR="$LABDIR/logs"
mkdir -p "$LOGDIR"
levels=(INFO WARN ERROR)

# Seed for reproducibility
SEED=12345
RANDOM=$SEED

# Helper to format timestamps
gen_timestamp() {
  # Fixed fake date range: 2026-01-15 10:00:00 to 10:30:00 UTC
  local start="2026-01-15 10:00:00"
  local end="2026-01-15 10:30:00"
  # Convert to seconds since epoch
  local s=$(date -d "$start" +%s)
  local e=$(date -d "$end" +%s)
  local diff=$((e - s))
  local offset=$((RANDOM % diff))
  date -u -d "@$((s + offset))" "+%d/%b/%Y:%H:%M:%S +0000"
}

# Synthetic Nginx access log (combined format)
generate_access_log() {
  local file="$LOGDIR/access.log"
  > "$file"
  local statuses=(200 200 200 301 404 500 502)
  local endpoints=("/" "/login" "/api/items" "/api/orders" "/static/app.js")
  local users=("demo-user" "test-admin" "alpha" "beta")
  for i in {1..1000}; do
    local ip="192.0.2.$((RANDOM % 254 + 1))"
    local ts=$(gen_timestamp)
    local method="GET"
    local endpoint="${endpoints[$((RANDOM % ${#endpoints[@]}))]}"
    local protocol="HTTP/1.1"
    local status="${statuses[$((RANDOM % ${#statuses[@]}))]}"
    local size=$((RANDOM % 5000 + 200))
    echo "$ip - - [$ts] \"$method $endpoint $protocol\" $status $size \"-\" \"-\"" >> "$file"
  done
  # Add a burst of 5xx errors
  for i in {1..30}; do
    local ip="192.0.2.$((RANDOM % 254 + 1))"
    local ts=$(gen_timestamp)
    local endpoint="/api/orders"
    local status=500
    local size=$((RANDOM % 300 + 100))
    echo "$ip - - [$ts] \"GET $endpoint $protocol\" $status $size \"-\" \"-\"" >> "$file"
  done
  # Gzip a small slice as older log
  head -n 200 "$file" > "$LOGDIR/access.log.1"
  gzip -c "$LOGDIR/access.log.1" > "$LOGDIR/access.log.1.gz"
  rm "$LOGDIR/access.log.1"
}

# Synthetic application log (plain text)
generate_app_log() {
  local file="$LOGDIR/app.log"
  > "$file"
  local levels=(INFO WARN ERROR)
  for i in {1..500}; do
    local ts=$(date -u -d "@$(($SEED + i*60))" "+%Y-%m-%d %H:%M:%S")
    local lvl="${levels[$((RANDOM % ${#levels[@]}))]}"
    if (( i % 50 == 0 )); then
      echo "$ts [$lvl] Configuration error: missing variable XYZ" >> "$file"
    else
      echo "$ts [$lvl] Normal operation message $i" >> "$file"
    fi
  done
}

# JSON‑lines version of a subset of the same events
generate_json_log() {
  local file="$LOGDIR/app.json.log"
  > "$file"
  for i in {1..200}; do
    local ts=$(date -u -d "@$(($SEED + i*120))" "+%Y-%m-%dT%H:%M:%SZ")
    local lvl="${levels[$((RANDOM % ${#levels[@]}))]}"
    local msg="Message $i"
    if (( i % 40 == 0 )); then
      msg="Configuration error: missing variable XYZ"
    fi
    echo "{\"timestamp\": \"$ts\", \"level\": \"$lvl\", \"message\": \"$msg\"}" >> "$file"
  done
}

# Synthetic auth log (sshd‑style)
generate_auth_log() {
  local file="$LOGDIR/auth.log"
  > "$file"
  local users=("demo-user" "test-admin" "alice" "bob")
  for i in {1..200}; do
    local ip="192.0.2.$((RANDOM % 254 + 1))"
    local user="${users[$((RANDOM % ${#users[@]}))]}"
    local ts=$(date -u -d "@$(($SEED + i*180))" "+%b %d %H:%M:%S")
    if (( i % 33 == 0 )); then
      echo "$ts $HOSTNAME sshd[${RANDOM}]: Failed password for $user from $ip port 22 ssh2" >> "$file"
    else
      echo "$ts $HOSTNAME sshd[${RANDOM}]: Accepted password for $user from $ip port 22 ssh2" >> "$file"
    fi
  done
}

# Write a marker that this data is synthetic
echo "SYNTHETIC DATA – DO NOT TREAT AS REAL LOGS" > "$LOGDIR/SYNTHETIC-DATA.txt"

# Run generators
generate_access_log
generate_app_log
generate_json_log
generate_auth_log

echo "Synthetic logs generated under $LOGDIR"
