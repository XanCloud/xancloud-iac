---
name: xancloud-iac-review
description: >
  Code review especializado para código HCL del proyecto xancloud-iac (OpenTofu, NO Terraform).
  Trigger cuando se pida revisar código HCL existente, analizar un módulo, buscar problemas,
  se comparta código para feedback, se diga "review", "revisar", "analizar", "chequear",
  "qué está mal", "mejorar", "optimizar", o se pegue un bloque de código HCL para evaluación.
  También trigger cuando se comparta un PR, diff, o se pida validar que el código cumple
  con las convenciones del proyecto. Trigger ante cualquier código HCL compartido que no sea
  una solicitud explícita de generación — si el usuario comparte código, probablemente quiere feedback.
---

# XanCloud IaC — Code Review

## Formato de review

Cada hallazgo lleva severity tag:

- 🔴 **Critical** — Riesgo de seguridad, pérdida de datos, estado roto, credenciales expuestas
- 🟡 **Important** — Violación de best practice, guardrail faltante, convención del proyecto ignorada
- 🔵 **Improvement** — Optimización, legibilidad, DRY, naming

Siempre mostrar el fix, no solo el problema. Usar bloques de reemplazo directos.

```
🔴 **IAM policy con wildcard sin justificación**

Actual:
​```hcl
actions = ["*"]
​```

Fix:
​```hcl
actions = [
  "s3:GetObject",
  "s3:PutObject",
  "s3:ListBucket",
]
​```
```

## Checklist de review (verificar todo, reportar solo hallazgos)

### Seguridad (🔴 si falla)
- [ ] Sin credenciales hardcoded (access keys, passwords, tokens)
- [ ] IAM sin `"*"` en actions/resources sin comentario justificativo
- [ ] Encriptación at-rest en todo recurso que la soporte (S3, EBS, RDS, SQS, SNS, etc.)
- [ ] S3 buckets sin public access (block_public_access)
- [ ] Security groups sin `0.0.0.0/0` en ingress sin justificación
- [ ] IMDSv2 enforced en instancias EC2
- [ ] Sin `prevent_destroy = false` explícito en recursos de producción

### Convenciones del proyecto (🟡 si falla)
- [ ] Tags obligatorios presentes: Environment, Project, Owner, ManagedBy, CostCenter
- [ ] Naming sigue `{project}-{env}-{service}-{resource}`
- [ ] Variables con `type` + `description` + `validation` donde aplique
- [ ] Outputs con `description`
- [ ] `versions.tf` con `required_version >= 1.11.0` y providers `~>`
- [ ] Sin backend block en módulos (solo en blueprints/environments)
- [ ] Sin referencias a Terraform Cloud, Sentinel, DynamoDB locking
- [ ] Comandos/comentarios usan `tofu`, no `terraform`
- [ ] Servicios de seguridad con `enabled = false` por defecto (excepto CloudTrail)
- [ ] Estructura de archivos: main.tf, variables.tf, outputs.tf, versions.tf, locals.tf

### Calidad (🔵 si falla)
- [ ] Locals usados para valores derivados (no repetir expresiones)
- [ ] Provider version constraints con `~>` (no pinned exacto, no `>=` abierto)
- [ ] Lifecycle policies en S3 buckets, ECR repos, CloudWatch log groups
- [ ] `for_each` sobre maps/sets en vez de `count` para colecciones con identidad
- [ ] Recursos con `depends_on` solo cuando la dependencia no es inferible
- [ ] Sin recursos deprecated (Launch Configurations, Classic ELB, etc.)
- [ ] Outputs exportan IDs y ARNs necesarios para composición

### Pipeline compatibility (🟡 si falla)
- [ ] `tofu fmt` pasaría sin cambios
- [ ] `tofu validate` pasaría
- [ ] Checkov no encontraría findings críticos

## Contexto del proyecto

Decisiones de diseño vigentes que afectan el review:

- **Single account MVP** — No multi-account hasta Fase 2. Si el código asume Organizations/SCPs, señalar.
- **Sin Transit Gateway** — VPC peering o endpoints, no TGW hasta Fase 2.
- **OpenTofu >= 1.11** — Puede usar features de 1.11 (state encryption, S3 native locking).
- **Checkov, no Sentinel** — Policy engine open source.

## Formato de salida

Ordenar hallazgos por severidad (🔴 → 🟡 → 🔵). Si no hay hallazgos, decir "Sin hallazgos" y nada más. No inflar reviews con felicitaciones.

Si el código es extenso, agrupar por archivo. Si hay más de 5 hallazgos del mismo tipo, resumir el patrón y dar un fix genérico en vez de repetir N veces.

Al final del review (solo si hay hallazgos), un resumen de una línea:

```
**Resumen:** X críticos, Y importantes, Z mejoras.
```
