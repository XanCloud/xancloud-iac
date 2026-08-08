# Estado actual del proyecto

Última actualización: 2026-08-08

## Fase activa: 1 — MVP

### Código

| Componente | Estado | Rama | Validado |
|-----------|--------|------|----------|
| state-backend | Completo | `main` | `tofu validate` ✅ |
| networking/vpc | Completo | `main` | `tofu validate` ✅ |
| security/cloudtrail | Completo | `main` | `tofu validate` ✅ |
| identity/iam-baseline | Completo | `main` | `tofu validate` ✅ |
| landing-zone-basic | Completo | `main` | `tofu validate` ✅ |

### Infraestructura desplegada

Deploy end-to-end validado y destroy limpio verificado el 2026-06-06.

| Entorno | Estado | Fecha |
|---------|--------|-------|
| dev | ✅ Deploy -> Verificar -> Destroy | 2026-06-06 |

### Git

- **Branch principal:** `main`
- **Tags:** `v0.1.0` (creado)
- **Releases:** v0.1.0 (creado)

### Pendiente para cerrar Phase 1

- [x] Merge `feature/phase-1-mvp-complete` → `main`
- [x] Commitear `.terraform.lock.hcl` (trackeado, fuera de `.gitignore`)
- [x] Crear `environments/dev/terraform.tfvars.example` y `environments/prod/terraform.tfvars.example`
- [x] Deploy de prueba end-to-end en entorno dev
- [x] Validar destroy limpio (orden inverso)
- [x] Tag `v0.1.0` y release en GitHub

### Próximos pasos

1. Buscar primer cliente (trigger de Phase 2)

### Backlog técnico para Phase 2

Estos items están identificados, documentados, y se abordarán cuando se active Phase 2 (primer cliente):

| ID | Item | Prioridad | Notas |
|----|------|-----------|-------|
| B2 | KMS en CloudWatch Logs de flow logs | Alta | Flow logs sin encriptación KMS. Crear CMK dedicada. |
| B3 | SSE-KMS con CMK en flow logs S3 | Alta | Actualmente usa AWS-managed key (`aws/s3`). Usar CMK. |
| B6 | Validación programática de singleton iam-baseline | Media | `precondition` block que evite drift entre estados. |
| B11 | Cross-region replication del state bucket | Alta | Sin CRR, fallo de región = pérdida de state. |
| B12 | CloudWatch Alarms | Alta | Sin monitoreo: CloudTrail validation, KMS deletion, S3 policy changes. |
| B13 | Drift detection | Media | Sin `prevent_destroy` en state bucket ni KMS key. |
| B14 | Module versioning en blueprint sources | Media | Sources usan paths relativos sin versión. Migrar a referencias versionadas. |
| B15 | Reducir duplicación de variables blueprint↔módulo | Baja | Evaluar objetos tipados (`cloudtrail_config = {...}`). |
| B16 | Refactor VPC main.tf (>500 líneas) | Baja | Extraer `endpoints.tf` y `flow-logs.tf`. |
| B17 | Refactor `cloudtrail/locals.tf:17` bucket_arn | Baja | Usar `one(aws_s3_bucket.trail[*].arn)` para robustez. |
| B18 | Agregar `.tflint.hcl` y tflint al pre-commit | Media | Detecta deprecated attributes, naming conventions. |
| B19 | Evaluar `default_tags` en provider AWS | Baja | Eliminaría ~30 líneas de `merge()` repetitivo. |
| — | CI/CD: GitHub Actions + OIDC | Alta | Ya documentado en PHASE-2.md. |
| — | Policy scanning: Checkov ≥ 3.2.x | Alta | Ya documentado en PHASE-2.md. |
| — | Testing: `tofu test` + Terratest | Alta | Ya documentado en PHASE-2.md. |
| — | Docs: terraform-docs auto-generados | Media | Ya documentado en PHASE-2.md. |
