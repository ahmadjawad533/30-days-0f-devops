# Day 11 – AWS Cloud Foundations

**Purpose**: Introduce AWS global infrastructure concepts (Regions, Availability Zones, service scope) and provide a safe, read‑only inventory script.

**Safety**: This lab creates **no AWS resources**. The agent never runs the AWS CLI or reads credentials. The inventory script (`aws-readonly‑inventory.sh`) is **read‑only**, refuses to run as root, requires an explicit `LAB11_REGION` and confirmation variable, and redacts any identifiers before writing to `outputs/`.

**Prerequisites**
- An AWS account with MFA‑protected root user and billing alerts set (see `docs/account-safety‑checklist.md`).
- A non‑root IAM identity (covered in Day 12) that has at least `sts:GetCallerIdentity` and `ec2:Describe*` permissions.
- AWS CLI installed locally (follow the official guide; the agent does not install it).

**Order of operations**
1. Read the documentation in `docs/` (hierarchy, service‑scope, mapping, region‑decision worksheet, safety checklist).
2. Run `./static-checks.sh` to verify the lab scripts and documentation are clean.
3. (After Day 12) Set `LAB11_REGION` and `LAB11_CONFIRM=yes`, then run `./aws-readonly‑inventory.sh`.
4. Review the redacted output files in `outputs/` before committing.

**Documentation ↔ Output mapping**
| Document | Output file | Concept demonstrated |
|----------|-------------|----------------------|
| `docs/aws-hierarchy.md` | – | Global AWS infrastructure layout |
| `docs/service-scope-table.md` | – | Service scope definitions |
| `docs/service-mapping-table.md` | – | Mapping AWS services to Linux/Docker equivalents |
| `docs/region-decision.md` | – | Worksheet for selecting a Region |
| `docs/account-safety-checklist.md` | – | Checklist for secure account usage |
| `aws-readonly‑inventory.sh` | `outputs/01‑cli‑version.txt` … `outputs/05‑summary.txt` | Read‑only inventory of regions & AZs |

**Before you publish**
- Inspect every file in `outputs/` for accidental leakage of account IDs, ARNs, or keys.
- Ensure all tables in `service‑scope-table.md` and `service‑mapping-table.md` still contain the placeholder `TO VERIFY` marker.
- Verify the PR contains the updated root README entry for Day 11.

**Article**: *[link TBD]*
