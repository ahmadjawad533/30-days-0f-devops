# Day 05 – Linux Log Management & Troubleshooting

## Purpose
This lab demonstrates how to inspect system logs, generate synthetic log data, rotate logs safely, and troubleshoot common logging issues on a typical systemd‑based Linux workstation.

## Safety Statement
* `inspect-logging.sh` only reads metadata and counts from the host’s journal; it never prints log message text, usernames, hostnames, or IP addresses.
* `run-lab.sh` works exclusively inside the project‑local `lab-workdir/` directory (git‑ignored). No real system logs are read or written.
* The optional *user‑journal‑lab* scripts are **write‑only** and must be reviewed before execution. They never run automatically.

## Prerequisites
- Bash, coreutils, awk, grep, gzip, zcat, zgrep, systemd utilities (`systemctl`, `journalctl`, `logger`, `systemd-cat`).
- Optional: `python3` (for synthetic data generation), `jq` (JSON log analysis), `logrotate` (log rotation demos), `shellcheck` (linting).

## How to Run
```bash
./inspect-logging.sh   # read‑only inspection of the host journal
./run-lab.sh           # generate synthetic logs and run all demos
```
All script output files are written to `outputs/`.

## Demo Overview
| Demo | What it Shows | Concept |
|------|---------------|---------|
| 01 Components | Systemd component status (journald, rsyslog, syslog‑ng) | Service availability |
| 02 Journal storage | Where the journal stores its files, disk usage | Persistence |
| 03 Journal config | Contents of `journald.conf` (sanitized) | Configuration |
| 04 Journal access | Group membership for journal access | Permissions |
| 05 Aggregate counts | Message priority distribution, top units (via `jq`) | Structured analysis |
| 06 Boot availability | Number of recorded boots | History depth |
| 07 /var/log metadata | File list with sizes/modes (redacted names) | Filesystem layout |
| 08 Logrotate presence | Version, unit files, config metadata | Rotation tooling |
| 09 Timers | Logrotate‑related timers | Scheduling |
| 10 Time settings | Timezone and NTP sync status | Clock configuration |
| 11 Kernel log access | `kernel.dmesg_restrict` value | Kernel security |
| 12 Disk use summary | `df -h` for repo and `/var/log` | Storage usage |
| 13 Context note | “Local desktop, not EC2” | Environment |
| 01 Synthetic logs | Deterministic fake access/app/auth logs | Data generation |
| 02 Access log analysis | Status code distribution, top endpoints, burst detection | Log parsing |
| 03 Error spike | Identify 5xx burst window | Troubleshooting |
| 04 App log analysis | Level counts, repeated config error extraction | Structured logs |
| 05 JSON log analysis | Error filtering with `jq` (optional) | JSON handling |
| 06 Auth log analysis | Failed/accepted login counts (synthetic) | Security audit |
| 07 Compressed logs | `zcat`/`zgrep` demo on `.gz` file | Compression |
| 08 Locale pitfall | `sort`/`uniq` with/without `LC_ALL=C` | Locale effects |
| 09 Logrotate dry‑run | `logrotate -d` with project config | Rotation preview |
| 10 Logrotate real run | Actual rotation, retention, compression | Rotation in action |
| 11 Open FD demo | Tail‑follow a moved file, show inode binding | File descriptor behavior |
| 12 Disk use | `du -sh` before/after rotation | Disk impact |

## Before You Publish
* Review every file in `outputs/` for accidental personal data (usernames, hostnames, IPs, machine IDs). Redact as `<redacted‑...>` if needed.
* Ensure all addresses in the synthetic logs are from the RFC 5737 ranges (e.g., `192.0.2.*`).
* Verify that no raw system log contents are committed.

## Documentation
* See the logging pipeline overview in [`docs/logging-pipeline.md`](docs/logging-pipeline.md).

## Article
* Article: *[link TBD]*
