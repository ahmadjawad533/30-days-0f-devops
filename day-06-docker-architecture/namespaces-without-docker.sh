#!/usr/bin/env bash
set -u

# Directory for outputs (relative to this script)
OUT_DIR="$(dirname "${BASH_SOURCE[0]}")/../outputs"
mkdir -p "$OUT_DIR"

time_stamp() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

log_file() {
  local file="$1"
  local cmd="$2"
  echo "# Command: $cmd" > "$OUT_DIR/$file"
  echo "# Timestamp: $(time_stamp)" >> "$OUT_DIR/$file"
  eval "$cmd" >> "$OUT_DIR/$file" 2>&1
  echo "# End of $file" >> "$OUT_DIR/$file"
}

# Helper to check command existence
check_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# 01 Host baseline
if check_cmd id && check_cmd hostname && check_cmd readlink; then
  log_file "01-host-baseline.txt" "id -u && hostname && readlink -f /proc/self/ns/{pid,mnt,uts,net,user,ipc}"
else
  echo "Skipping 01-host-baseline: required commands missing" > "$OUT_DIR/01-host-baseline.txt"
fi

# 02 User namespace mapping
if check_cmd unshare; then
  log_file "02-user-ns.txt" "unshare --user --map-root-user sh -c 'id; cat /proc/self/uid_map'"
else
  echo "Skipping 02-user-ns: unshare missing" > "$OUT_DIR/02-user-ns.txt"
fi

# 03 PID namespace demo
if check_cmd unshare; then
  log_file "03-pid-ns.txt" "unshare --user --map-root-user --pid --fork --mount-proc sh -c 'echo \"my pid: $$\"; ps -o pid,ppid,comm'"
else
  echo "Skipping 03-pid-ns: unshare missing" > "$OUT_DIR/03-pid-ns.txt"
fi

# 04 UTS namespace demo
if check_cmd unshare; then
  # Capture host hostname first
  HOSTNAME_BEFORE=$(hostname)
  log_file "04-uts-ns.txt" "unshare --user --map-root-user --uts sh -c 'hostname lab06-demo; hostname'"
  # Verify host unchanged
  echo "# Host hostname after UTS demo: $HOSTNAME_BEFORE" >> "$OUT_DIR/04-uts-ns.txt"
else
  echo "Skipping 04-uts-ns: unshare missing" > "$OUT_DIR/04-uts-ns.txt"
fi

# 05 Network namespace demo
if check_cmd unshare && check_cmd ip; then
  log_file "05-net-ns.txt" "unshare --user --map-root-user --net sh -c 'ip -o link show'"
  # Host count for comparison
  HOST_COUNT=$(ip -o link show | wc -l)
  echo "# Host network interfaces count: $HOST_COUNT" >> "$OUT_DIR/05-net-ns.txt"
else
  echo "Skipping 05-net-ns: unshare or ip missing" > "$OUT_DIR/05-net-ns.txt"
fi

# 06 Namespace comparison
if check_cmd unshare; then
  log_file "06-ns-comparison.txt" "unshare --user --map-root-user --pid --uts --net --fork sh -c 'readlink /proc/self/ns/user /proc/self/ns/pid /proc/self/ns/uts /proc/self/ns/net'"
  # Host links for reference
  echo "# Host namespace links:" >> "$OUT_DIR/06-ns-comparison.txt"
  readlink /proc/self/ns/{user,pid,uts,net} >> "$OUT_DIR/06-ns-comparison.txt" 2>/dev/null || true
else
  echo "Skipping 06-ns-comparison: unshare missing" > "$OUT_DIR/06-ns-comparison.txt"
fi

# 07 Not a container note
cat <<'EOF' > "$OUT_DIR/07-not-a-container.txt"
This demonstration uses only Linux kernel namespaces. No Docker image, no cgroup limits, no seccomp, and no Docker daemon are involved.
EOF

# End of script
