#!/usr/bin/env bash
set -euo pipefail

# This script demonstrates writing to the per‑user journal using the `logger` command.
# It does NOT require any privileged systemd unit to be started; the `logger`
# command forwards messages to `systemd-journald` for the current user.

echo "Starting User Journal Lab..."

# Emit a few log lines with different priorities and tags.
logger -t lab05-logger "INFO: Lab started"
logger -p user.warn -t lab05-logger "WARN: Simulated warning"
logger -p user.err -t lab05-logger "ERROR: Simulated error"

# Show the messages (optional – for local verification).
# The user can view them with: journalctl --user -t lab05-logger

echo "Messages logged. You can view them with:"
echo "  journalctl --user -t lab05-logger"
