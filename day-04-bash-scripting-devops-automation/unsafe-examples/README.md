# Unsafe Shell Patterns vs. Hardened Practices

> [!CAUTION]
> **DO NOT EXECUTE `unsafe-cleanup.sh.txt`!**
> This file is intentionally stored as plain text without execution permissions to demonstrate anti-patterns that have caused real-world outages and data loss in production environments.

---

## Anatomy of the Vulnerability

Consider the classic flawed cleanup snippet:

```bash
set -e
TARGET_DIR=
rm -rf $TARGET_DIR/*
```

### Flaw 1: Unquoted Variable Expansion
- If `$TARGET_DIR` is empty or unset, the shell evaluates `rm -rf /*`, which expands to root directories (`/bin`, `/etc`, `/usr`, `/var`, `/home`) and executes `rm -rf` against the entire filesystem.
- If `$TARGET_DIR` contains spaces (e.g. `/tmp/my app/data`), unquoted `$TARGET_DIR` word-splits into `/tmp/my` and `app/data`.

### Flaw 2: Missing Unset Variable Guards (`set -u`)
- Without `set -u`, referencing an unassigned or typo-ridden variable (e.g. `$TARG_DIR`) silently evaluates to an empty string rather than halting.

### Flaw 3: Blind Faith in `set -e`
- `set -e` does not prevent unquoted expansions or empty variable disaster commands.
- It can also abruptly terminate scripts mid-operation without releasing locks or cleaning up temporary scratch files.

---

## The Hardened Remediation (`fixed-cleanup.sh`)

1. **Strict Flags:** `set -uo pipefail` ensures unset variables fail fast and pipeline errors are surfaced.
2. **Parameter Expansion Guard:** `: "${target_dir:?error message}"` triggers an immediate fatal error if the variable is null or empty before any command executes.
3. **Canonical Path Boundary Check (`realpath`):** Resolves symlinks and relative elements (`..`), verifying that the target directory resides strictly inside an approved workspace.
4. **Dry-Run by Default:** Requires an explicit flag (e.g. `-f`) to perform deletions.

---

## Relevant Static Analysis Categories (ShellCheck)

When running static analysis on shell scripts, these patterns correspond to key security categories:
- **Quote expansions to prevent word splitting:** Flagged when variables inside commands (especially file paths) lack double quotes.
- **Check for unset or unassigned variables:** Flagged when variables are referenced before assignment or without default fallbacks.
- **Dangerous `rm -rf` expansions:** Flagged when `rm -rf` targets could resolve to `/` or an unconstrained variable.
