# 30 Days of DevOps: From Linux Administration to AWS Cloud Engineering

Welcome to **30 Days of DevOps: From Linux Administration to AWS Cloud Engineering**, a hands-on learning series by Ahmad Jawad Bandesha. This series documents an open, practical journey across core DevOps domains—progressing from foundational Linux OS internals and system administration to containerization, AWS cloud architecture, CI/CD automation, infrastructure as code, and production observability. The project focuses on learning in public with an honest, engineering-grounded approach without hype or shortcuts.

---

## Series Roadmap

| Day | Topic | Status | Article | Code |
| :---: | :--- | :---: | :---: | :---: |
| - | Series introduction | Planned | TBD | TBD |
| **Phase 1** | **Linux and Automation** | | | |
| 01 | Linux Architecture Explained: What Every DevOps Engineer Should Know | Planned | TBD | TBD |
| 02 | Linux Server Administration: Users, Groups and File Permissions | Planned | TBD | TBD |
| 03 | Linux Process and Service Management with systemd | Planned | TBD | TBD |
| 04 | Bash Scripting for DevOps: Automating Everyday Linux Tasks | Planned | TBD | TBD |
| 05 | Linux Log Management and Troubleshooting for Cloud Engineers | Planned | TBD | TBD |
| **Phase 2** | **Docker and Containers** | | | |
| 06 | Docker Architecture Explained: Images, Containers and Docker Engine | Planned | TBD | TBD |
| 07 | Writing Production-Ready Dockerfiles: Containerizing a Python Application | Planned | TBD | TBD |
| 08 | Docker Volumes and Networking: Managing Container Data and Communication | Planned | TBD | TBD |
| 09 | Docker Compose: Running Multi-Container Applications | Planned | TBD | TBD |
| 10 | Docker Security Best Practices: Building Smaller and Safer Containers | Planned | TBD | TBD |
| **Phase 3** | **AWS Cloud Infrastructure** | | | |
| 11 | AWS Cloud Computing Explained: Regions, Availability Zones and Core Services | Planned | TBD | TBD |
| 12 | AWS IAM Deep Dive: Understanding Roles, Policies and Least Privilege | Planned | TBD | TBD |
| 13 | Amazon EC2 Explained: Launching and Managing Linux Cloud Servers | Planned | TBD | TBD |
| 14 | AWS VPC Architecture: Building Secure Public and Private Subnets | Planned | TBD | TBD |
| 15 | AWS Security Groups vs. Network ACLs | Planned | TBD | TBD |
| 16 | Amazon S3 Deep Dive | Planned | TBD | TBD |
| 17 | Deploying a Web Application on AWS EC2 with Nginx and HTTPS | Planned | TBD | TBD |
| 18 | AWS Load Balancing and Auto Scaling | Planned | TBD | TBD |
| **Phase 4** | **CI/CD and Deployment Automation** | | | |
| 19 | CI/CD Explained: From Manual Deployments to Automation | Planned | TBD | TBD |
| 20 | GitHub Actions: Building Your First Automated CI Pipeline | Planned | TBD | TBD |
| 21 | Automating Docker Builds and Deployments Using GitHub Actions and Amazon ECR | Planned | TBD | TBD |
| 22 | Building an End-to-End CI/CD Pipeline for AWS EC2 | Planned | TBD | TBD |
| **Phase 5** | **Infrastructure as Code** | | | |
| 23 | Infrastructure as Code Explained: Getting Started with Terraform and AWS | Planned | TBD | TBD |
| 24 | Provisioning AWS Infrastructure with Terraform: VPC, Subnets and EC2 | Planned | TBD | TBD |
| 25 | Terraform State Management and Remote Backends Using Amazon S3 | Planned | TBD | TBD |
| **Phase 6** | **Monitoring, Security and Cloud Operations** | | | |
| 26 | AWS CloudWatch Explained: Monitoring EC2 Instances and Applications | Planned | TBD | TBD |
| 27 | Building an AWS Monitoring and Alerting System with CloudWatch and SNS | Planned | TBD | TBD |
| 28 | AWS Security and Reliability: Secrets Management, CloudTrail and Backup Strategies | Planned | TBD | TBD |
| **Phase 7** | **Production DevOps Capstone** | | | |
| 29 | Designing a Production-Ready AWS DevOps Architecture: From Code to Deployment | Planned | TBD | TBD |
| 30 | 30 Days of DevOps: Building an Automated AWS Deployment Platform from Scratch | Planned | TBD | TBD |

---

## Repository Structure

The repository is organized on a day-by-day basis:
- `templates/day-template/`: Standard directory layout for each day's lab.
- `scripts/new-day.sh`: Helper script to scaffold a new day's workspace.
- `docs/safety-and-cost.md`: Practical guidelines for local execution safety, cloud cost control, and sensitive output scrubbing.
- `day-NN-<slug>/`: Dedicated directory for each lab (added progressively on its own branch).

---

## How to Use This Repository

1. Clone the repository and navigate into the project root.
2. Follow each day's dedicated lab instructions in its respective folder.
3. Review `docs/safety-and-cost.md` before executing any script or provisioning cloud resources.

---

## Safety and Cost Notice

- All lab scripts are educational and designed to run safely and non-destructively in read-only mode or inside local temporary directories unless explicitly stated otherwise.
- For AWS cloud exercises, labs outline expected resource scopes, costs, and teardown steps. Always verify billing alerts and destroy resources when done.

---

## License

This repository is licensed under the [MIT License](LICENSE).
