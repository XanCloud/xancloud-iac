# xancloud-iac — Contexto del proyecto

## Objetivo

Acelerador de consultoría IaC basado en **OpenTofu** (no Terraform) para AWS. Proporciona módulos reutilizables y un blueprint de landing zone para arrancar entornos seguros y auditable en contextos multi-cuenta y multi-entorno.

## Alcance MVP (v0.1.0)

- **4 módulos**: state-backend, networking/vpc, security/cloudtrail, identity/iam-baseline.
- **1 blueprint**: landing-zone-basic (orquesta los módulos).
- **Entornos**: dev, prod (estructura bajo `environments/`).
- **Binario**: `tofu` (OpenTofu ≥ 1.11.0). AWS Provider ~> 6.0.

## Qué resuelve

- **Consistencia**: Mismos patrones (state, red, seguridad, identidad) en distintos proyectos.
- **Velocidad**: Menor tiempo hasta el primer deploy con módulos y blueprint listos.
- **Cumplimiento**: CloudTrail, IAM baseline, S3 block public access, IMDSv2 por defecto.
- **Portabilidad**: OpenTofu + HCL estándar; sin dependencia de Terraform propietario.

## Modelo

Este repositorio es la **base abierta** (OpenCore). Las capacidades avanzadas
(multi-account, CI/CD, SSO, security scanning) están disponibles como extensiones
privadas para clientes de consultoría. Ver [PHASE-2.md](PHASE-2.md) para el detalle
de extensiones.

## Fases completadas

| Fase   | Enfoque                          | Estado    |
|--------|-----------------------------------|-----------|
| Phase 0 | Validación + Go-to-Market        | Completada ✅ |
| Phase 1 | MVP (módulos + blueprint)        | Completada ✅ |

## Documentación relacionada

- [PHASE-0.md](PHASE-0.md) — Validación y go-to-market.
- [PHASE-1.md](PHASE-1.md) — MVP y entregables.
- [PHASE-2.md](PHASE-2.md) — Capacidades privadas (consultoría).
- [PHASE-3.md](PHASE-3.md) — Futuro.
- [DECISIONS.md](DECISIONS.md) — Decisiones de arquitectura y proceso.
- [RISKS.md](RISKS.md) — Riesgos y mitigaciones.
