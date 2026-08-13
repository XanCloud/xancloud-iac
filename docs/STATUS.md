# Estado actual del proyecto

Última actualización: 2026-08-12

## Alcance: OpenCore foundation

Este repositorio contiene la base abierta del modelo OpenCore. Las capacidades avanzadas
(multi-account, CI/CD, SSO, security scanning) están disponibles como extensiones privadas
para clientes de consultoría. Este repositorio se mantiene as-is; la comunidad es libre de
forkear, adaptar y construir sobre esta base.

### Código

| Componente | Estado | Validado |
|-----------|--------|----------|
| state-backend | Completo | `tofu validate` ✅ |
| networking/vpc | Completo | `tofu validate` ✅ |
| security/cloudtrail | Completo | `tofu validate` ✅ |
| identity/iam-baseline | Completo | `tofu validate` ✅ |
| landing-zone-basic | Completo | `tofu validate` ✅ |

### Infraestructura desplegada

Deploy end-to-end validado y destroy limpio verificado el 2026-06-06.

| Entorno | Estado | Fecha |
|---------|--------|-------|
| dev | ✅ Deploy -> Verificar -> Destroy | 2026-06-06 |

### Git

- **Branch principal:** `main`
- **Tag:** `v0.1.0`
- **Release:** v0.1.0

### Mejoras abiertas a la comunidad

Estos items están identificados como áreas donde la comunidad puede contribuir:

| Área | Descripción |
|------|-------------|
| KMS en flow logs | Flow logs a CloudWatch y S3 sin CMK propia. Agregar KMS dedicada. |
| Cross-region replication | State bucket sin replicación cross-region. |
| CloudWatch Alarms | Sin alarmas para CloudTrail validation, KMS deletion, S3 policy changes. |
| Drift detection | Sin `prevent_destroy` en state bucket ni KMS key. |
| Module versioning | Sources del blueprint usan paths relativos. Migrar a referencias versionadas. |
| tflint | Agregar `.tflint.hcl` y tflint al pre-commit. |
| Refactor VPC | `main.tf` del módulo VPC >500 líneas. Extraer `endpoints.tf` y `flow-logs.tf`. |

> Las contribuciones son bienvenidas via PR. Ver [AGENTS.md](../AGENTS.md) para convenciones.
