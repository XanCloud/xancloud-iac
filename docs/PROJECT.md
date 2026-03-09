# xancloud-iac — Contexto del proyecto

## Objetivo

Acelerador de consultoría IaC basado en **OpenTofu** (no Terraform) para AWS. Proporciona módulos reutilizables y un blueprint de landing zone para arrancar entornos seguros y auditable en contextos multi-cuenta y multi-entorno.

## Alcance MVP (v0.2.0)

- **4 módulos**: state-backend, networking/vpc, security/cloudtrail, identity/iam-baseline.
- **1 blueprint**: landing-zone-basic (orquesta los módulos).
- **Entornos**: dev, prod (estructura bajo `environments/`).
- **Binario**: `tofu` (OpenTofu ≥ 1.11.0). AWS Provider ~> 5.0.

## Qué resuelve

- **Consistencia**: Mismos patrones (state, red, seguridad, identidad) en distintos proyectos.
- **Velocidad**: Menor tiempo hasta el primer deploy con módulos y blueprint listos.
- **Cumplimiento**: CloudTrail, IAM baseline, S3 block public access, IMDSv2 por defecto.
- **Portabilidad**: OpenTofu + HCL estándar; sin dependencia de Terraform propietario.

## Fases

| Fase   | Enfoque                          | Condición                    |
|--------|-----------------------------------|------------------------------|
| Phase 0 | Validación + Go-to-Market        | Activa                       |
| Phase 1 | MVP (módulos + blueprint)        | Activa                       |
| Phase 2 | Industrialización (CI/CD, tests) | Requiere primer cliente      |
| Phase 3 | Escalar o pivotar                 | Requiere datos reales        |

## Documentación relacionada

- [PHASE-0.md](PHASE-0.md) — Validación y go-to-market.
- [PHASE-1.md](PHASE-1.md) — MVP y entregables.
- [PHASE-2.md](PHASE-2.md) — Industrialización.
- [PHASE-3.md](PHASE-3.md) — Escala o pivote.
- [DECISIONS.md](DECISIONS.md) — Decisiones de arquitectura y proceso.
- [RISKS.md](RISKS.md) — Riesgos y mitigaciones.
