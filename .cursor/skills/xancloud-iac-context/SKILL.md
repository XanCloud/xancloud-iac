---
name: xancloud-iac-context
description: >
  Contexto general del proyecto xancloud-iac. Actúa como fallback cuando ningún skill más
  específico aplica. Trigger para cualquier conversación dentro del proyecto xancloud-iac
  que no active otro skill: preguntas sobre el proyecto en general, su visión, fases,
  decisiones de diseño, convenciones, roadmap, modelo de negocio, licenciamiento, riesgos,
  o estado actual. También trigger cuando se pregunte "en qué fase estamos", "qué falta",
  "cuál es la prioridad", "qué decidimos sobre X", o cualquier meta-pregunta sobre el proyecto.
  Trigger incluso para orientar al usuario hacia el skill más específico cuando la pregunta
  lo amerite. Si el usuario habla de xancloud-iac sin un contexto técnico específico, este
  skill carga el contexto necesario para responder con conocimiento del proyecto.
---

# XanCloud IaC — Project Context

## Qué es

Acelerador de consultoría IaC basado en OpenTofu para AWS. Landing zone opinada con módulos reutilizables, blueprints y pipelines CI/CD.

**No vende código. Vende reducción de time-to-production y transferencia de conocimiento.**

## Estado actual

**Fase activa:** 1 — MVP Landing Zone (Capa 0)
**Estado:** No iniciada (repo vacío, documentación completa)

No trabajar en entregables de fases futuras a menos que se pida explícitamente.

## Fases

| Fase | Nombre | Dependencia | Estado |
|---|---|---|---|
| 1 | MVP Landing Zone | Ninguna | No iniciada |
| 2 | Multi-Account | Fase 1 | No iniciada |
| 3 | Blueprints de Workload | Fase 1 | No iniciada (paralela con F2) |
| 4 | Operaciones Día 2 | Fase 1 | No iniciada (paralela con F2-3) |
| 5 | Producto | Fase 3 | No iniciada |

Para detalles de cada fase, consultar `references/phases-summary.md`.

## Stack (no negociable en Fase 1)

- **IaC:** OpenTofu >= 1.11.0 (binario: `tofu`, NO `terraform`)
- **Cloud:** AWS
- **CI/CD:** GitHub Actions
- **Testing:** tofu test + Terratest
- **Policy:** Checkov + OPA/Rego
- **Docs:** terraform-docs + MkDocs
- **State:** S3 + KMS, `use_lockfile = true`, sin DynamoDB

## Decisiones de diseño vigentes

| # | Decisión | Elección |
|---|---|---|
| 1 | IaC Tool | OpenTofu (no Terraform) |
| 2 | Account strategy | Single account con tags (MVP) |
| 3 | VPC connectivity | Sin Transit Gateway (Fase 1) |
| 4 | NAT Gateway | Single en dev/staging, per-AZ en prod |
| 5 | State locking | S3 native (sin DynamoDB) |
| 6 | CI/CD | GitHub Actions (no Azure DevOps) |
| 7 | Policy engine | Checkov + OPA (no Sentinel) |
| 8 | Registry | Dual: GitHub (público) + OCI/ECR (clientes) |
| 9 | Security services | enabled=false por defecto (excepto CloudTrail) |
| 10 | VPCs | Map iterable con for_each |

Si una propuesta contradice estas decisiones, señalarlo explícitamente antes de continuar.

## Convenciones rápidas

- **Tags obligatorios:** Environment, Project, Owner, ManagedBy, CostCenter
- **Naming:** `{project}-{env}-{service}-{resource}`
- **Encriptación:** at-rest obligatoria en todo recurso
- **IAM:** least privilege, sin `*` injustificados
- **Providers:** version constraints con `~>`
- **Módulos:** main.tf, variables.tf, outputs.tf, versions.tf, locals.tf, examples/, tests/

## Routing a skills específicos

| Si la pregunta es sobre... | Redirigir a |
|---|---|
| Crear/editar código HCL de módulos | `xancloud-iac-modules` |
| GitHub Actions, CI/CD, pipelines | `xancloud-iac-pipeline` |
| Review de código, feedback | `xancloud-iac-review` |
| Tests, tofu test, Terratest | `xancloud-iac-testing` |
| Blueprints, composición, environments | `xancloud-iac-blueprint` |
| Checkov, OPA, policies, SCPs | `xancloud-iac-security` |
| Documentación, runbooks, diagramas | `xancloud-iac-docs` |
| Scaffold de cliente, onboarding | `xancloud-iac-client` |

## Qué NO hacer (reglas del proyecto)

- No proponer Terraform Cloud, Sentinel, remote runs
- No usar DynamoDB para state locking
- No generar código sin tags obligatorios
- No asumir multi-account hasta Fase 2
- No usar Launch Configurations (Launch Templates)
- No usar IMDSv1

## Modelo de negocio (referencia)

- **Módulos core:** Apache 2.0 (open source)
- **Blueprints, policies, templates:** Repositorio privado (parte del servicio)
- **Documentación de producto:** Privada (valor diferencial)

Pricing: Consultoría $3K-$8K, Soporte mensual $500-$2K, Blueprints Premium $1K-$3K/año, Training $500-$1.5K/sesión.
