# XanCloud IaC — Contexto del Proyecto

> **Versión:** 0.1.0 | **Estado:** En desarrollo | **Última actualización:** Marzo 2026

## Qué es esto

Acelerador de consultoría basado en OpenTofu. Landing zone AWS opinada compuesta por módulos reutilizables, blueprints pre-armados y pipelines CI/CD listos para producción.

**No vende código. Vende reducción de time-to-production y transferencia de conocimiento estructurada.**

## Stack

| Componente | Elección | Justificación |
|---|---|---|
| IaC Tool | OpenTofu >= 1.11 | MPL 2.0, sin restricción comercial. State encryption built-in. OCI registry nativo. S3 native locking. |
| Cloud | AWS (primaria) | Mayor cuota de mercado. Extensión a Azure/GCP en fases posteriores. |
| CI/CD | GitHub Actions | Integración nativa con GitHub. Migración a Azure DevOps documentada. |
| Testing | tofu test + Terratest | tofu test para validación rápida. Terratest para integración con recursos reales. |
| Policy | Checkov + OPA/Rego | Checkov para escaneo estático. OPA para policies custom en pipeline. |
| Docs | terraform-docs + MkDocs | Auto-generación de inputs/outputs. MkDocs para documentación de producto. |
| Registry | GitHub Releases + OCI (ECR) | GitHub para open-source/portfolio. OCI para clientes con módulos privados. |

### Versiones mínimas

- OpenTofu: >= 1.11.0 (stable: 1.11.5)
- AWS Provider: >= 5.x (hashicorp/aws)
- Checkov: >= 3.2.x (stable: 3.2.506)
- GitHub Actions Runner: ubuntu-latest

## Estructura del repositorio

```
xancloud-iac/
├── modules/                          # EL PRODUCTO - módulos reutilizables
│   ├── networking/vpc/               # VPC con subnets, NAT, flow logs, endpoints
│   ├── security/guardduty/           # GuardDuty (enabled = false por defecto)
│   ├── security/securityhub/         # SecurityHub (enabled = false por defecto)
│   ├── security/config-rules/        # AWS Config managed rules (enabled = false por defecto)
│   ├── security/cloudtrail/          # CloudTrail multi-region
│   ├── identity/sso/                 # IAM Identity Center config
│   ├── identity/iam-baseline/        # Password policy, account-level settings
│   ├── state-backend/                # S3 + KMS (use_lockfile, sin DynamoDB)
│   └── operations/
│       ├── monitoring/               # CloudWatch dashboards + alertas base
│       └── cost-mgmt/               # Budgets + anomaly detection
├── blueprints/
│   └── landing-zone-basic/           # Capa 0 completa (MVP)
├── environments/
│   ├── dev/                          # terraform.tfvars + backend.hcl
│   ├── staging/
│   └── prod/
├── .github/workflows/                # CI/CD pipelines
├── tests/                            # tofu test + Terratest suites
├── policies/                         # Checkov custom checks + OPA policies
├── docs/                             # Runbooks, arquitectura, onboarding
├── templates/client-scaffold/        # Generador de repo por cliente
└── README.md
```

### Estructura interna de módulos

Cada módulo sigue esta convención:

```
modules/networking/vpc/
├── main.tf          # Recursos principales
├── variables.tf     # Inputs con type, description, default y validation blocks
├── outputs.tf       # Outputs con description
├── versions.tf      # required_providers con version constraints (~>)
├── locals.tf        # Valores derivados y lógica de tags
├── README.md        # Auto-generado con terraform-docs
├── examples/        # Al menos un ejemplo funcional
│   ├── simple/
│   └── multi-az/
└── tests/           # tofu test files
```

## Modelo de negocio

### Qué vende XanCloud

| Canal | Oferta | Pricing indicativo |
|---|---|---|
| Consultoría | Despliegue de landing zone + onboarding | Proyecto fijo ($3K-$8K) |
| Soporte | Mantenimiento continuo, drift resolution, upgrades | Retainer mensual ($500-$2K) |
| Blueprints Premium | Blueprints de workload (EKS, Serverless) con soporte | Licencia anual ($1K-$3K) |
| Training | Workshops de OpenTofu + AWS para equipos | Por sesión ($500-$1.5K) |

### Licenciamiento

- **Módulos core** (networking, security baseline): Apache 2.0 — open source.
- **Blueprints, policies, templates de cliente**: Repositorio privado. Parte del servicio.
- **Documentación de producto** (runbooks, guías): Privada. Valor diferencial.

## Convenciones

### Tags obligatorios

| Tag Key | Ejemplo | Propósito |
|---|---|---|
| Environment | dev / staging / prod | Segregación lógica |
| Project | xancloud-landing | Asignación de costos |
| Owner | platform-team | Responsable del recurso |
| ManagedBy | opentofu | Identifica recursos IaC |
| CostCenter | CC-001 | Tracking financiero |

### Naming

```
{project}-{env}-{vpc_key}-{service}-{resource}
```

### Criterios de calidad (CI bloqueante)

| Criterio | Métrica | Enforcement |
|---|---|---|
| Formato | `tofu fmt -check` pasa | CI bloqueante |
| Validación | `tofu validate` pasa | CI bloqueante |
| Security scan | 0 findings críticos Checkov | CI bloqueante |
| Testing | tofu test pasa para módulos modificados | CI bloqueante |
| Documentación | terraform-docs actualizado (diff = 0) | CI bloqueante |
| Tags | Todos los recursos con tags obligatorios | Checkov custom check |
| Encriptación | Todos los recursos at-rest encriptados | Checkov + Config rule |
