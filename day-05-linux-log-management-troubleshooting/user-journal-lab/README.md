# User Journal Lab

This optional lab demonstrates how to write custom messages to the **user journal** using a temporary `systemd` service.

## Files
- `run-journal-lab.sh` – Starts the logger service, emits a few log lines, and stops the service.
- `cleanup-journal-lab.sh` – Removes any generated journal files and unloads the service.
- `lab05-logger.service` – Minimal `systemd` unit that runs `logger` to write to the user journal.

## How to run
```bash
cd user-journal-lab
./run-journal-lab.sh   # generates logs in $HOME/.local/share/journal/user@... (read‑only for this lab)
journalctl --user -u lab05-logger.service   # view the logged messages
./cleanup-journal-lab.sh  # clean up after inspection
```

The lab does **not** modify any system‑wide configuration; it only writes to the per‑user journal which is safe under the repository sandbox.
