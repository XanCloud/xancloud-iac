<h1 align="center">xancloud-iac</h1>

<p align="center">
  <strong>Opinionated AWS landing zone accelerator built on OpenTofu.</strong><br>
  Deploy a secure, compliant AWS foundation in hours — not months.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg" alt="License"></a>
  <a href="https://opentofu.org"><img src="https://img.shields.io/badge/OpenTofu-%3E%3D1.11-blueviolet?logo=opentofu" alt="OpenTofu"></a>
  <a href="https://aws.amazon.com"><img src="https://img.shields.io/badge/cloud-AWS-FF9900?logo=amazonwebservices" alt="AWS"></a>
  <img src="https://img.shields.io/badge/status-Phase%201%20MVP-yellow" alt="Status">
</p>

---

**AWS landing zones take consultancies 3–6 months and $50K–$500K to deliver.** Most SMBs can't afford that. xancloud-iac gives you pre-built modules, production-ready blueprints, and clear defaults so you don't need a dedicated DevOps team to start right.

## Why xancloud-iac

- **Hours, not months** — A single `tofu apply` deploys a secure AWS foundation with VPC, IAM hardening, CloudTrail, and encrypted state.
- **OpenTofu-first** — MPL 2.0 license, native state encryption, S3 locking without DynamoDB. No vendor lock-in.
- **Opinionated defaults** — Every resource is encrypted at rest, tagged, and follows AWS Well-Architected. Zero manual configuration.
- **Built for LATAM SMBs** — Transparent pricing, compliance-ready modules, documentation in Spanish and English.

## Architecture

```
┌──────────────────────────────────────────────────┐
│                   Landing Zone                   │
│                                                  │
│  ┌───────────┐  ┌───────────┐                    │
│  │    VPC    │  │    VPC    │  ...N              │
│  │   (dev)   │  │  (prod)   │                    │
│  └───────────┘  └───────────┘                    │
│                                                  │
│  ┌──────────────────────────────────────────────┐    │
│  │  IAM Baseline  ·  CloudTrail             │    │
│  │  S3 Block Public Access  ·  IMDSv2       │    │
│  └──────────────────────────────────────────────┘    │
│                                                  │
│  ┌──────────────────────────────────────────────┐    │
│  │  State: S3 + KMS  (use_lockfile)         │    │
│  └──────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────┘
```

## Quick start

```bash
# 1 — Bootstrap state backend (first time only)
cd modules/state-backend && tofu init && tofu apply

# 2 — Deploy landing zone
cd blueprints/landing-zone-basic
tofu init -backend-config=../../environments/dev/backend.hcl
tofu plan -var-file=../../environments/dev/terraform.tfvars
tofu apply
```

> **Prerequisites:** [OpenTofu >= 1.11](https://opentofu.org/docs/intro/install) · AWS CLI configured

## Stack

| Layer | Tool | Details |
|-------|------|---------|
| **IaC** | OpenTofu >= 1.11 | State encryption, S3 native locking, MPL 2.0 |
| **Cloud** | AWS | Primary target. Largest market share. |
| **Policy** | Checkov + OPA | Static security scanning (Phase 2+) |
| **Testing** | tofu test + Terratest | Unit + integration tests (Phase 2+) |
| **CI/CD** | GitHub Actions | Automated quality gates (Phase 2+) |

## Project structure

```
modules/                  # ← Reusable modules (the product)
├── state-backend/        #    S3 + KMS, bootstrap manual
├── networking/vpc/       #    VPC, subnets, NAT, endpoints, flow logs
├── security/cloudtrail/  #    Multi-region audit trail
└── identity/iam-baseline/#    IMDSv2, S3 block public access, password policy

blueprints/               # ← Opinionated module compositions
└── landing-zone-basic/   #    Connects all 4 modules with env defaults

environments/             # ← Per-environment configuration
├── dev/                  #    terraform.tfvars + backend.hcl
└── prod/                 #    terraform.tfvars + backend.hcl
```

## Who is this for

| Audience | Problem xancloud-iac solves |
|----------|----------------------------|
| **SMBs starting on AWS** | Security and compliance from day one, without a DevOps team |
| **Mid-size companies** | Existing infra that's manually managed, drifting, and costing too much |
| **Consultants & freelancers** | A repeatable, professional-grade starting point for client engagements |

## Why OpenTofu over Terraform

OpenTofu is the open-source fork of Terraform under the MPL 2.0 license. After IBM's acquisition of HashiCorp and the BSL license change, OpenTofu provides freedom from vendor lock-in, predictable licensing, and features like native state encryption and S3 locking without DynamoDB — making it the better foundation for new projects in 2026.

## Roadmap

- [x] Technical spec approved
- [ ] **Phase 0** — Validation + Go-to-Market *(active)*
- [ ] **Phase 1** — Minimum Viable Product *(active)*
- [ ] Phase 2 — Industrialization *(requires first client)*
- [ ] Phase 3 — Scale or Pivot *(requires real data)*

See [`docs/`](docs/) for full project context, design decisions, and phased roadmap.

## Contributing

This project follows [Conventional Commits](https://www.conventionalcommits.org/), uses GitHub Flow branching, and enforces OpenTofu conventions documented in [`docs/`](docs/).

## License

[Apache 2.0](LICENSE)
