# Safety, Security, and Cost Guidelines

This document outlines key practices for safely running the labs in this series while preventing unexpected cloud expenses or credential exposure.

---

## 1. Local Safety
- Unless explicitly stated otherwise in a specific lab guide, scripts and exercises are designed to run read-only or scoped strictly inside the repository workspace (`lab-workdir/` or `tmp/`).
- Do not run commands requiring root (`sudo`) unless a specific lab explicitly documents administrative requirements.

---

## 2. Cloud Safety and Cost Management
- **Explicit Lab Details:** Every AWS cloud lab will explicitly document the required IAM permissions, targeted region, anticipated costs, and teardown steps.
- **Cleanup Responsibility:** Always tear down provisioned cloud resources (`terraform destroy` or manual cleanup commands) as soon as you finish a lab.
- **Sandbox Accounts:** Where possible, use a dedicated sandbox AWS account separate from production or business environments.
- **Billing Alerts:** Set up AWS CloudWatch billing alarms and AWS Budgets early. Refer to the official AWS documentation for instructions on configuring billing alerts.

---

## 3. Credential and Secret Management
- **Never commit credentials:** Do not commit AWS credentials (`~/.aws/credentials`), API access keys, SSH keys (`.pem`, `.key`), `.env` files, `.tfvars`, or Terraform state files (`.tfstate`).
- Keep `.gitignore` updated with project-specific sensitive file types.

---

## 4. Output Redaction
- Before committing outputs captured during hands-on exercises, review all files in `outputs/` for personal data (such as hostnames, usernames, internal IP addresses, or unique machine IDs).
- Replace sensitive tokens with standardized markers like `<redacted-hostname>` or `<redacted-ip>`.
