# Phase 1 — Minimum Viable Product (MVP)

## Objetivo

Entregar un conjunto mínimo de módulos OpenTofu y un blueprint de landing zone que permitan desplegar una base segura y auditable en una cuenta AWS.

## Módulos (4)

1. **state-backend**: S3 + DynamoDB (lock) + KMS para state remoto. Uso de `use_lockfile` donde aplique.
2. **networking/vpc**: VPC con subnets públicas/privadas, NAT, flujo estándar para dev/prod.
3. **security/cloudtrail**: Trail con cifrado, integración S3/CloudWatch según especificación.
4. **identity/iam-baseline**: Políticas base (S3 block public access, IMDSv2, etc.) y roles mínimos.

## Blueprint (1)

- **landing-zone-basic**: Composición de los 4 módulos; entrada por entorno (dev/prod) vía `environments/`.

## Entregables

- Código HCL en cada módulo (variables tipadas, descripciones, validación).
- Blueprint que invoque los módulos y permita `tofu init` / `tofu plan` / `tofu apply`.
- Documentación mínima por módulo (README, inputs/outputs).
- Sin tests automatizados ni pipelines en esta fase (Phase 2).

## Criterios de salida

- `tofu validate` y `tofu fmt` pasan en todos los módulos y en el blueprint.
- Un entorno de ejemplo (p. ej. dev) aplicable de punta a punta.
- DECISIONS.md y RISKS.md actualizados con decisiones técnicas tomadas.
