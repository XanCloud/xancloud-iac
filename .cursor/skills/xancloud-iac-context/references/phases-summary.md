# Resumen de Fases

## Fase 1 — MVP Landing Zone (4-6 semanas)

**Entregables:**
- state-backend (S3 + KMS, bootstrap manual)
- networking/vpc (iterable con for_each)
- identity/sso (Permission sets + grupos)
- identity/iam-baseline (Account-level settings)
- security/cloudtrail (enabled=true)
- security/guardduty (enabled=false)
- security/securityhub (enabled=false)
- security/config-rules (enabled=false)
- operations/monitoring (CloudWatch base)
- operations/cost-mgmt (Budgets + anomaly)
- blueprints/landing-zone-basic (composición)
- CI/CD pipelines (5 workflows)

**Orden:** repo scaffold → state-backend → vpc + tests → CI básico → security + identity → blueprint → environments + deploy pipeline

**Completitud:** tofu apply from scratch, tests en CI, 0 Checkov críticos, READMEs generados, deploy pipeline con approval.

## Fase 2 — Multi-Account (3-4 semanas)

AWS Organizations, OUs, SCPs, Transit Gateway, state en cuenta dedicada.

**Decisiones pendientes:** Control Tower vs Organizations raw, cuenta de log archive, número de OUs, TGW vs VPC Peering.

## Fase 3 — Blueprints de Workload (2-3 semanas/blueprint)

ECS Fargate, Serverless API, EKS Platform. Módulos transversales: S3, monitoring, backup.

Paralela con Fase 2.

## Fase 4 — Operaciones Día 2 (2-3 semanas)

Drift detection mejorado, cost monitoring, backup/DR, runbooks operativos, dashboards consolidados.

Paralela con Fases 2-3.

## Fase 5 — Producto (4-6 semanas)

MkDocs site, OCI registry, client scaffold, demo environment, onboarding automatizado.

Requiere Fase 3 completa (al menos 2 blueprints).
