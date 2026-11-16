# Day 02: Linux Server Administration: Users, Groups and File Permissions

Article: [AWS Builder Center: Day 02 - Linux Server Administration](https://builder.aws.com/content/3M8Dj3jwVHdHkzUAzCtfpy35xJJ/day-02-linux-server-administration-users-groups-and-file-permissions)

Welcome to Day 02 of the **30 Days of DevOps** series. Mastering Linux identity, ownership, and permissions is the bedrock of server hardening, container privilege separation, CI/CD runner isolation, and cloud infrastructure security. This lab combines read-only identity inspection with project-local, unprivileged permission experiments to illustrate how the Linux kernel evaluates access.

---

## Purpose

The objective of Day 02 is to move past surface-level `chmod 777` habits and develop a precise mental model of:
- **User and Group Representation:** How Linux resolves UID, primary GID, supplementary groups, and system account boundaries (< 1000).
- **The Kernel Permission Evaluation Algorithm:** Why "Owner Class Wins" and how evaluation stops at the first matching identity tier.
- **Directory Traversal Semantics:** Why directory read (`r`) and directory execute (`x`) serve fundamentally different purposes, and why file deletion depends strictly on parent directory write permissions.
- **Special Permission Bits:** Practical behavior of SUID, SGID on directories (group inheritance), and the Sticky Bit (`/tmp`).
- **Access Control Lists (ACLs) & SSH StrictModes:** Advanced permission masks and SSH client/server permission requirements.
- **Least-Privilege Sudoers:** Designing narrow, wildcard-free administrative delegations for service accounts.

---

## Safety Statement

- **`inspect-identity.sh` is strictly read-only:** It does not invoke `sudo`, does not modify any system files, and never prints private credentials or contents of sensitive databases like `/etc/shadow` or `~/.ssh`.
- **`permissions-lab.sh` is strictly project-local:** It runs completely unprivileged (no `sudo`) and creates files only inside a local, gitignored `lab-workdir/` folder, which is cleanly destroyed at the end.
- **`optional-user-lab/` is NEVER executed by automation:** The scripts in this subfolder (`setup-lab-users.sh`, `cleanup-lab-users.sh`, and `sudoers-lab02-deploy.example`) are written solely for manual review or experimentation in a disposable VM. They are never run automatically.

---

## Prerequisites

Standard Linux core utilities found on modern Linux distributions:
- `bash` (version 4.0+)
- `coreutils` (`id`, `ls`, `chmod`, `stat`, `umask`, `touch`, `mkdir`, `rm`, `cat`, `cut`, `sort`, `uniq`, `awk`)
- `util-linux` (`namei`)
- Optional tools:
  - `acl` (`setfacl`, `getfacl`; if missing, the ACL demonstration skips gracefully).

---

## How to Run

1. Navigate to the Day 02 directory:
   ```bash
   cd day-02-users-groups-permissions
   ```
2. Make scripts executable:
   ```bash
   chmod +x inspect-identity.sh permissions-lab.sh
   ```
3. Run the read-only identity inspector:
   ```bash
   ./inspect-identity.sh
   ```
4. Run the project-local permissions lab:
   ```bash
   ./permissions-lab.sh
   ```

Both scripts are idempotent; re-running them cleanly overwrites existing `.txt` files in `outputs/`.

---

## Lab Breakdown & Concepts Demonstrated

### Part 1: Read-Only Identity Inspection (`inspect-identity.sh`)

| Section | Command(s) Executed | What It Shows | Linux Architecture & Admin Concept |
| :---: | :--- | :--- | :--- |
| **01** | `id; id -un; id -gn; id -Gn` | Real UID, GID, and list of all supplementary group memberships. | **Process Identity**: How the kernel associates calling process credentials with security tokens. |
| **02** | `getent passwd $(id -un); getent group $(id -gn)` | The passwd entry for current user and primary GID. | **NSS (Name Service Switch)**: How glibc abstracts user lookup across `/etc/passwd` or network databases. |
| **03** | `ls -l /etc/passwd /etc/group /etc/shadow` | File ownership and permission bits of local authentication databases. | **Authentication Security**: Demonstrates `/etc/shadow` isolation (`-rw-r-----` root:shadow) vs world-readable passwd. |
| **04** | `awk` count on `/etc/passwd`; grep `UID_MIN/MAX` | Count of system accounts (UID < 1000) vs regular accounts (UID >= 1000). | **System vs Regular Accounts**: Privilege isolation for background daemons and service users. |
| **05** | `cut -d: -f7 /etc/passwd \| sort \| uniq -c` | Aggregate distribution of login shells across all system accounts. | **Shell Security**: Demonstrates the prevalence of non-interactive shells (`/usr/bin/nologin`, `/bin/false`). |
| **06** | `getent group wheel / sudo \| cut -d: -f1,3` | Verification of admin groups present on the system. | **Administrative Escalation**: The standard groups conferring `sudo` privileges on Arch/Debian derivatives. |
| **07** | `umask; umask -S` | Active file mode creation mask for the current shell in octal and symbolic form. | **Default Permission Masking**: How initial creation modes (`666` file, `777` dir) are subtracted at runtime. |
| **08** | `ls -ld /tmp; stat /usr/bin/passwd /usr/bin/sudo` | The Sticky Bit on `/tmp` (`drwxrwxrwt`) and SUID bit (`-rwsr-xr-x`). | **Special Permission Bits**: Temporary directory protection and controlled root privilege escalation. |
| **09** | `find /usr/bin /usr/sbin -perm /6000` | Inventory of all SUID and SGID executables on the system. | **Attack Surface Audit**: Auditing binaries capable of changing effective credentials during execution. |
| **10** | `stat "$HOME"` and `~/.ssh` | Metadata and permission bits on the user's home and `.ssh` directory. | **StrictModes & Privacy**: Requirements for SSH access and user profile directory security. |
| **11** | Host Context Note | Verification that execution took place on a local desktop, not an AWS cloud server. | **Environment Context**: Clear demarcation between desktop lab testing and cloud infrastructure. |

### Part 2: Project-Local Permissions Lab (`permissions-lab.sh`)

| Demo | What It Demonstrates | Linux Concept Explained |
| :---: | :--- | :--- |
| **A** | `chmod` with octal (`640`, `400`) and symbolic (`g+w,o+r`). | **Octal vs Symbolic Modes**: Changing standard user, group, and other permission triplets. |
| **B** | Subshell `umask 077` vs `022`. | **Process Environment Isolation**: Umask inheritance across subshells without mutating the parent shell. |
| **C** | Directory with `400` (read only) vs `100` (execute only). | **Directory Traversal Semantics**: Read (`r`) allows listing names; execute (`x`) allows inode resolution and traversal (`cd`). |
| **D** | Deleting a `444` file from a `755` directory vs attempting delete from a `555` directory. | **Deletion Ownership**: File deletion is a directory mutation (unlinking an entry in the parent directory table). |
| **E** | File with mode `047` (owner: `---`, group: `r--`, other: `rwx`). | **Owner-Class-Wins**: If process EUID matches owner UID, only owner bits are checked; access is denied immediately. |
| **F** | Directory with mode `1777` (Sticky Bit). | **Sticky Bit (`t`)**: Restricts deletion and renaming in shared directories strictly to file owners. |
| **G** | Directory with mode `2775` (SGID bit). | **SGID Inheritance**: Files created in an SGID directory automatically inherit the directory's group. |
| **H** | Nested path resolution with `namei -l`. | **VFS Path Traversal**: Step-by-step verification of execute permissions on all parent path components. |
| **I** | `setfacl` and `getfacl` extended permissions. | **POSIX ACLs**: Granting granular per-user permissions beyond standard Owner/Group/Other triplets. |
| **J** | Simulated SSH private key permissions (`600` vs `644`). | **SSH StrictModes**: OpenSSH client refusal of private keys with open permissions. |

---

## Reference Architecture & Diagrams

A comprehensive guide and diagram illustrating the kernel permission check algorithm is available at:
- [docs/permission-check.md](docs/permission-check.md) (features a Mermaid flowchart and an ASCII fallback).

---

## Optional Service User Simulation (`optional-user-lab/`)

For learners who wish to experiment with real service account creation and least-privilege sudoers delegation in an isolated VM:
- See the dedicated [optional-user-lab/README.md](optional-user-lab/README.md).

---

## Before You Publish

> [!WARNING]
> Before committing or pushing your generated `outputs/` folder to a public repository:
> - Review all generated `.txt` files in `outputs/` to ensure no sensitive personal data (e.g. your username, hostname, or personal home paths) are inadvertently exposed.
> - Replace sensitive values with standardized redactions such as `<redacted-username>` or `<redacted-home>`.
