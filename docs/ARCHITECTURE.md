# Arquitectura y dependencias

## Estructura del repositorio

```
xancloud-iac/
├── modules/                    Módulos reutilizables (atómicos)
│   ├── state-backend/          S3 + KMS para state remoto
│   ├── networking/vpc/         VPCs, subnets, NAT, endpoints, flow logs
│   ├── security/cloudtrail/    Trail multi-región, S3, KMS, CW Logs
│   └── identity/iam-baseline/  Hardening a nivel de cuenta
├── blueprints/                 Composiciones (orquestan módulos)
│   └── landing-zone-basic/     Landing zone MVP (vpc + cloudtrail + iam-baseline)
├── environments/               Configs por entorno (dev, prod)
└── docs/                       Documentación del proyecto
```

## Mapa de dependencias

```
┌─────────────────────────────────────────────────────────┐
│                    BOOTSTRAP (manual)                    │
│                                                         │
│   modules/state-backend                                 │
│   ├── Input:  bucket_name, project, environment         │
│   └── Output: bucket_id, kms_key_arn, backend_config    │
│                         │                               │
│                         ▼                               │
│              backend-{env}.hcl                          │
│   (bucket, region, encrypt, kms_key_id, use_lockfile)   │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              BLUEPRINT: landing-zone-basic               │
│              Backend: S3 (via -backend-config)           │
│                                                         │
│   ┌─────────────────┐  ┌──────────────────────┐        │
│   │ module "vpc"     │  │ module "cloudtrail"   │        │
│   │                  │  │                       │        │
│   │ Input:           │  │ Input:                │        │
│   │  vpcs (map)      │  │  enabled              │        │
│   │                  │  │  multi_region          │        │
│   │ Creates:         │  │  cw_logs_enabled       │        │
│   │  VPCs            │  │                       │        │
│   │  Subnets pub/prv │  │ Creates:              │        │
│   │  NAT Gateways    │  │  CloudTrail trail     │        │
│   │  Route Tables    │  │  S3 bucket (logs)     │        │
│   │  VPC Endpoints   │  │  KMS key              │        │
│   │  Flow Logs       │  │  CW Log Group (opt)   │        │
│   └─────────────────┘  └──────────────────────┘        │
│                                                         │
│   ┌──────────────────────────────────────────────┐     │
│   │ module "iam_baseline"                         │     │
│   │ enabled = var.is_account_owner                │     │
│   │                                               │     │
│   │ Creates (SINGLETON, solo 1 env por cuenta):   │     │
│   │  S3 Account Public Access Block               │     │
│   │  IAM Password Policy                          │     │
│   │  Access Analyzer                              │     │
│   │  EC2 Instance Metadata Defaults (IMDSv2)      │     │
│   │  Account Alias (opcional)                     │     │
│   └──────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

## Flujo de datos entre módulos

Los módulos dentro del blueprint son **independientes entre sí**. No hay dependencias cruzadas:

- `vpc` no consume outputs de `cloudtrail` ni de `iam_baseline`
- `cloudtrail` no consume outputs de `vpc`
- `iam_baseline` no consume outputs de ningún otro módulo

La única dependencia real es:
- **state-backend → blueprint**: el bucket y KMS key del state-backend se pasan al blueprint via `-backend-config`

## Singleton constraint

`iam_baseline` maneja recursos a nivel de cuenta AWS (no por región ni por entorno):

| Recurso | Scope | Conflicto si duplicado |
|---------|-------|----------------------|
| `aws_iam_account_password_policy` | Cuenta | Drift en cada apply |
| `aws_s3_account_public_access_block` | Cuenta | Drift en cada apply |
| `aws_ec2_instance_metadata_defaults` | Región | Drift en cada apply |
| `aws_iam_account_alias` | Cuenta | Error directo |
| `aws_accessanalyzer_analyzer` | Región | No conflicto (nombres distintos) |

**Regla:** `is_account_owner = true` en exactamente UN entorno por cuenta. Convención Phase 1: **dev es el owner**.

## State layout

```
S3 bucket: {project}-{environment}-tfstate-{account-id}
├── state-backend/terraform.tfstate              (bootstrap, migrado desde local)
├── landing-zone-basic/dev/terraform.tfstate      (dev environment)
└── landing-zone-basic/prod/terraform.tfstate     (prod environment)
```

> El nombre del bucket incluye el account ID para garantizar unicidad global. Ejemplo: `xancloud-dev-tfstate-291066412211`.

Cada entorno tiene su propio state file con su propio lock. No comparten state.

## Red: layout de subnets

Para un VPC con CIDR `/16` y N availability zones:

```
10.X.0.0/16
├── Public subnets:   10.X.{0..N-1}.0/24    (1 por AZ, auto-assign public IP)
├── Private subnets:  10.X.{N..2N-1}.0/24   (1 por AZ, sin public IP)
├── NAT Gateways:     1 (single_nat=true) ó N (single_nat=false)
└── Route tables:     1 public (→ IGW) + N private (→ NAT)
```

Ejemplo dev (2 AZs, single NAT):
```
10.10.0.0/16
├── 10.10.0.0/24  public-us-east-1a
├── 10.10.1.0/24  public-us-east-1b
├── 10.10.2.0/24  private-us-east-1a  → NAT en us-east-1a
└── 10.10.3.0/24  private-us-east-1b  → NAT en us-east-1a (shared)
```

Ejemplo prod (3 AZs, NAT per-AZ):
```
10.20.0.0/16
├── 10.20.0.0/24  public-us-east-1a
├── 10.20.1.0/24  public-us-east-1b
├── 10.20.2.0/24  public-us-east-1c
├── 10.20.3.0/24  private-us-east-1a  → NAT en us-east-1a
├── 10.20.4.0/24  private-us-east-1b  → NAT en us-east-1b
└── 10.20.5.0/24  private-us-east-1c  → NAT en us-east-1c
```

## Scope Phase 1 vs Phase 2+

| Capacidad | Phase 1 | Phase 2+ |
|-----------|---------|----------|
| Cuenta AWS | Single | Multi-account (Organizations) |
| VPC connectivity | Aisladas | Transit Gateway, peering |
| IP | IPv4 only | IPv6 dual-stack |
| CloudTrail | Per-account | Organization trail |
| Security services | CloudTrail, IAM baseline | GuardDuty, SecurityHub, Config |
| CI/CD | Manual | GitHub Actions + OIDC |
| Tests | `tofu validate` | `tofu test`, Terratest, Checkov |
| Docs | Manual README | terraform-docs auto-generated |
| SSO | No | IAM Identity Center |
| State replication | Single region | Cross-region S3 replication |
