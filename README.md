# xancloud-iac

Acelerador de consultoría IaC — Landing Zone AWS con OpenTofu.

## Qué resuelve

Reduce el despliegue de infraestructura AWS de semanas a horas usando módulos pre-probados, blueprints opinados y pipelines CI/CD listos.

## Stack

- **IaC:** OpenTofu >= 1.11
- **Cloud:** AWS (primaria)
- **CI/CD:** GitHub Actions
- **Policy:** Checkov >= 3.2.x + OPA/Rego
- **Testing:** tofu test + Terratest
- **Registry:** GitHub Releases (público) + OCI/ECR (clientes)

## Arquitectura

```
┌─────────────────────────────────────────────────┐
│                  Landing Zone                    │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │   VPC    │  │   VPC    │  │   VPC    │ ...N  │
│  │  (dev)   │  │(staging) │  │  (prod)  │      │
│  └──────────┘  └──────────┘  └──────────┘      │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  IAM Identity Center (SSO)               │   │
│  │  CloudTrail │ GuardDuty* │ SecurityHub*  │   │
│  │  AWS Config* │ S3 Block Public Access    │   │
│  └──────────────────────────────────────────┘   │
│  * enabled = false por defecto                   │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  State: S3 + KMS (use_lockfile)          │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

## Estructura

```
xancloud-iac/
├── modules/              # Módulos reutilizables (el producto)
│   ├── networking/vpc/
│   ├── security/         # guardduty, securityhub, config-rules, cloudtrail
│   ├── identity/         # sso, iam-baseline
│   ├── state-backend/
│   └── operations/       # monitoring, cost-mgmt
├── blueprints/           # Composiciones opinadas
│   └── landing-zone-basic/
├── environments/         # tfvars por entorno
│   ├── dev/
│   ├── staging/
│   └── prod/
├── .github/workflows/    # CI/CD
├── tests/                # tofu test + Terratest
├── policies/             # Checkov + OPA
├── docs/                 # Contexto del proyecto
│   ├── PROJECT.md        # Visión general
│   ├── PHASE-1.md        # MVP Landing Zone
│   ├── PHASE-2.md        # Multi-account
│   ├── PHASE-3.md        # Blueprints de workload
│   ├── PHASE-4.md        # Operaciones Día 2
│   ├── PHASE-5.md        # Producto
│   ├── DECISIONS.md      # ADRs (Architecture Decision Records)
│   └── RISKS.md          # Riesgos y mitigaciones
└── templates/            # Scaffold para nuevos clientes
```

## Pre-requisitos

- OpenTofu >= 1.11 instalado
- AWS CLI configurado con credenciales (SSO o access keys para dev)
- GitHub account con acceso a la org XanCloud

## Uso rápido

```bash
# 1. Bootstrap del state backend (solo la primera vez, manual)
cd modules/state-backend
tofu init
tofu apply

# 2. Desplegar landing zone en dev
cd blueprints/landing-zone-basic
tofu init -backend-config=../../environments/dev/backend.hcl
tofu plan -var-file=../../environments/dev/terraform.tfvars
tofu apply
```

## Inputs / Outputs

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Estado del proyecto

- [x] Especificación técnica aprobada
- [ ] **Fase 1:** MVP Landing Zone (en curso)
- [ ] Fase 2: Multi-account
- [ ] Fase 3: Blueprints de workload
- [ ] Fase 4: Operaciones Día 2
- [ ] Fase 5: Producto

## Contribuir

Ver [docs/](docs/) para contexto completo del proyecto, decisiones de diseño y roadmap por fases.
