# Troubleshooting Queries Cheat‑Sheet

## General Log‑Analysis Questions
| Question | Command (example) | What to Look For |
|----------|-------------------|-----------------|
| Which HTTP status codes are most common? | `awk '{print $9}' access.log | sort | uniq -c | sort -nr` | Distribution of 200/301/404/5xx etc. |
| Which endpoint generated the most traffic? | `awk '{print $7}' access.log | sort | uniq -c | sort -nr | head` | Top URLs (e.g., `/api/items`). |
| Which client IPs produced the most requests? | `awk '{print $1}' access.log | sort | uniq -c | sort -nr | head` | Identify heavy hitters (use RFC 5737 range). |
| When did a 5xx burst occur? | `awk '{print $4}' access.log | cut -d':' -f1-2 | uniq -c | sort -nr` | Look for minutes with many 5xx responses. |
| How many log entries per boot session? | `journalctl --list-boots --no-pager | wc -l` (already in inspection) |
| Are there any configuration‑error lines in app.log? | `grep -i "configuration error" app.log` | Repeating error pattern for the article. |
| How many ERROR level messages in JSON log? | `jq -r '.level' app.json.log | grep -c "ERROR"` |
| Failed vs accepted SSH logins? | `grep "Failed password" auth.log | wc -l` and `grep "Accepted password" auth.log | wc -l` |
| Does logrotate rotate the logs as expected? | Run `logrotate -d ...` (dry‑run) and inspect the state file. |
| Are there locale‑dependent sorting differences? | Compare `sort file.txt` vs `LC_ALL=C sort file.txt`. |

## Specific Lab Steps
- **Synthetic log generation** – runs `generate-synthetic-logs.sh`.
- **Logrotate demo** – uses `lab05-app.conf` with `@LABDIR@` substitution.
- **Open‑FD demo** – tail a file, move it, inspect `/proc/<pid>/fd`.

Feel free to adapt the commands to your environment; all paths are relative to the lab directory.
