# Estado actual del proyecto

Última actualización: 2026-08-06

## Fase activa: 1 — MVP

### Tooling de agentes (OpenCode)

| Componente | Estado |
|-----------|--------|
| `opencode.jsonc` + `.opencode/` | Implementado, versionado, validado contra schema (OpenCode 1.18.14) |
| MCP OpenTofu remoto | Conectado (`https://mcp.opentofu.org/mcp`, v1.0.1) |
| Routing de modelos | Nativo por agente (`model` en frontmatter, IDs verificados contra catálogo OpenRouter) |
| OpenRouter Presets | Opcional, no bloqueante (solo aportarían fallbacks y gestión centralizada) |
| Smoke tests de routing en vivo | Pendientes de reinicio de OpenCode |
| Retiro legacy (.kilo/, .kilocode/, .claude/) | Pendiente de aprobación explícita |

Detalle y matriz de paridad: `plans/opencode-agent-framework.md`.

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
