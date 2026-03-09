# xancloud-iac

Consulting accelerator for AWS Infrastructure as Code based on **OpenTofu** (not Terraform). Provides reusable modules and a landing-zone blueprint to bootstrap secure, auditable multi-account/multi-environment setups.

## What it solves

- **Consistency**: Same patterns (state, networking, security, identity) across engagements.
- **Speed**: Pre-built modules and one blueprint reduce time to first deploy.
- **Compliance**: CloudTrail, IAM baseline, S3 block public access, IMDSv2-ready defaults.
- **Portability**: OpenTofu + standard HCL; no Terraform-specific lock-in.

## Stack

| Layer    | Technology                    |
|----------|-------------------------------|
| IaC      | OpenTofu ≥ 1.11               |
| Cloud    | AWS (primary)                 |
| CI/CD    | GitHub Actions (Phase 2+)     |
| Policy   | Checkov ≥ 3.2.x + OPA/Rego (Phase 2+) |
| Testing  | `tofu test` + Terratest (Phase 2+)   |

## Architecture (high level)

```
┌─────────────────────────────────────────────────┐
│                  Landing Zone                    │
│                                                  │
│  ┌──────────┐  ┌──────────┐                     │
│  │   VPC    │  │   VPC    │  ...N               │
│  │  (dev)   │  │  (prod)  │                     │
│  └──────────┘  └──────────┘                     │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  IAM Baseline │ CloudTrail               │   │
│  │  S3 Block Public Access │ IMDSv2         │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  State: S3 + KMS (use_lockfile)          │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

## Repository structure

```
xancloud-iac/
├── modules/           # Reusable OpenTofu modules
│   ├── state-backend/
│   ├── networking/vpc/
│   ├── security/cloudtrail/
│   └── identity/iam-baseline/
├── blueprints/        # Composed solutions
│   └── landing-zone-basic/
├── environments/      # Environment-specific roots (dev, prod)
│   ├── dev/
│   └── prod/
├── docs/              # Project spec, phases, decisions, risks
└── .github/           # PR/issue templates
```

## Prerequisites

- **OpenTofu** ≥ 1.11.0 (`tofu` binary; not `terraform`)
- **AWS Provider** ~> 5.0
- AWS credentials (env vars, profile, or IRSA) for the target account(s)

## Quick start

```bash
# Clone and enter repo
git clone <repo-url> xancloud-iac && cd xancloud-iac

# Install pre-commit (optional)
pre-commit install

# Validate (once modules have .tf)
cd modules/state-backend && tofu init -backend=false && tofu validate
```

Module and blueprint implementation will be added in subsequent commits. See [docs/](docs/) for full project context.

## Project status

- [x] Technical spec approved
- [ ] **Phase 0:** Validation + Go-to-Market (active)
- [ ] **Phase 1:** Minimum Viable Product (active)
- [ ] Phase 2: Industrialization (requires first client)
- [ ] Phase 3: Scale or Pivot (requires real data)

## Documentation

| Document   | Description                    |
|-----------|---------------------------------|
| [docs/PROJECT.md](docs/PROJECT.md) | Project overview and scope   |
| [docs/PHASE-0.md](docs/PHASE-0.md) | Validation & go-to-market   |
| [docs/PHASE-1.md](docs/PHASE-1.md) | MVP (modules + blueprint)   |
| [docs/PHASE-2.md](docs/PHASE-2.md) | Industrialization           |
| [docs/PHASE-3.md](docs/PHASE-3.md) | Scale or pivot              |
| [docs/DECISIONS.md](docs/DECISIONS.md) | ADRs and key decisions |
| [docs/RISKS.md](docs/RISKS.md) | Risks and mitigations       |

## License

[Apache License 2.0](LICENSE). Copyright 2026 XanCloud.
