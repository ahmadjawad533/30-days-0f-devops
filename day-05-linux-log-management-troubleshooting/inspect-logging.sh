#!/usr/bin/env bash
set -u

# Ensure outputs directory exists
mkdir -p outputs

# Helper to write command and timestamp to output file
log_output() {
  local file=$1
  shift
  local cmd="$@"
  echo "# Command: $cmd" > "outputs/$file"
  echo "# Timestamp: $(date --iso-8601=seconds)" >> "outputs/$file"
  eval "$cmd" >> "outputs/$file" 2>&1
  echo "# End of $file" >> "outputs/$file"
}

# Section 01: Components
log_output "01-components.txt" "systemctl is-active systemd-journald; systemctl is-active rsyslog || true; systemctl is-active syslog-ng || true"
log_output "01-components-enabled.txt" "systemctl is-enabled systemd-journald; systemctl is-enabled rsyslog || true; systemctl is-enabled syslog-ng || true"

# Section 02: Journal storage
log_output "02-journal-storage.txt" "ls -ld /var/log/journal /run/log/journal 2>/dev/null || true"
log_output "02-journal-disk-usage.txt" "journalctl --disk-usage 2>/dev/null || echo 'journalctl not readable'"

# Section 03: Journal configuration
if [ -r /etc/systemd/journald.conf ]; then
  log_output "03-journald-conf.txt" "grep -v '^#' /etc/systemd/journald.conf | grep -v '^$'"
else
  echo "not readable" > outputs/03-journald-conf.txt
fi
if [ -d /etc/systemd/journald.conf.d ]; then
  for f in /etc/systemd/journald.conf.d/*.conf; do
    [ -r "$f" ] && log_output "03-journald-conf.d-$(basename "$f").txt" "grep -v '^#' \"$f\" | grep -v '^$'" || true
  done
fi

# Section 04: Journal access groups
log_output "04-groups.txt" "id -Gn | tr ' ' '\n' | grep -E 'systemd-journal|adm|wheel' || true"

# Section 05: Aggregate counts (priority and units)
if command -v jq >/dev/null; then
  log_output "05-priority-counts.txt" "journalctl -b -o json --no-pager 2>/dev/null | jq -r '.PRIORITY' | sort | uniq -c"
  # Top 10 units by message count
  log_output "05-top-units.txt" "journalctl -b -o json --no-pager 2>/dev/null | jq -r '."_SYSTEMD_UNIT"' | sort | uniq -c | sort -nr | head -n 10"
else
  echo "jq not installed" > outputs/05-priority-counts.txt
  echo "jq not installed" > outputs/05-top-units.txt
fi

# Section 06: Boot availability
log_output "06-boot-count.txt" "journalctl --list-boots --no-pager | wc -l"

# Section 07: /var/log metadata
log_output "07-varlog-metadata.txt" "ls -l /var/log | awk '{print $1, $3, $4, $5, $9}'"

# Section 08: Logrotate presence
log_output "08-logrotate-version.txt" "logrotate --version 2>/dev/null | head -n1 || echo 'logrotate not installed'"
log_output "08-logrotate-units.txt" "systemctl list-unit-files 'logrotate*' --no-legend --no-pager 2>/dev/null || true"
log_output "08-logrotate-config-metadata.txt" "ls -l /etc/logrotate.conf /etc/logrotate.d 2>/dev/null || echo 'logrotate config not readable'"

# Section 09: Timers
log_output "09-logrotate-timers.txt" "systemctl list-timers --all --no-pager 2>/dev/null | grep -i -E 'logrotate' || echo 'no logrotate timers found'"

# Section 10: Time settings
log_output "10-time-settings.txt" "timedatectl show -p Timezone -p NTPSynchronized --no-pager 2>/dev/null || echo 'timedatectl not available'"

# Section 11: Kernel log access restriction
log_output "11-dmesg-restrict.txt" "sysctl kernel.dmesg_restrict 2>/dev/null || echo 'sysctl not available'"

# Section 12: Disk use summary
log_output "12-df-repo.txt" "df -h ."
log_output "12-df-varlog.txt" "df -h /var/log 2>/dev/null || echo '/var/log not accessible'"

# Section 13: Context note
echo "# Context: This is a local desktop environment, not an EC2 instance" > outputs/13-context.txt
