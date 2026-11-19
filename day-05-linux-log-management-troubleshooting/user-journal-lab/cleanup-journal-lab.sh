#!/usr/bin/env bash
set -euo pipefail

# Cleanup script for the optional user journal lab.
# Removes any generated journal files under the user's local journal directory.
# This is safe because the lab only writes to the per‑user journal.

JOURNAL_DIR="$HOME/.local/share/systemd/journal"

if [ -d "$JOURNAL_DIR" ]; then
  echo "Removing user journal files in $JOURNAL_DIR..."
  rm -rf "$JOURNAL_DIR"/*
  echo "Cleanup complete."
else
  echo "User journal directory not found; nothing to clean."
fi
