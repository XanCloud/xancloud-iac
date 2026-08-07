# OpenCode Agent Framework para xancloud-iac: plan de implementación

**Estado:** implementado localmente (pendiente spike de presets y retiro legacy)
**Fecha:** 2026-08-06
**Runtime validado:** OpenCode 1.18.14
**Alcance:** configuración local del repositorio `xancloud-iac`
**Sustituye:** `plans/cep-agent-framework.md` (plan Kilo, retirado)

## 1. Objetivo

Equipo de agentes especializados sobre OpenCode, versionado en el propio
repositorio: coordinador primario `cep`, especialistas con permisos mínimos,
estándares bajo demanda, routing determinista mediante comandos y MCP
OpenTofu remoto oficial. `AGENTS.md` raíz sigue siendo la única autoridad
de reglas del proyecto.

Este documento cubre únicamente la implementación **local del repositorio**.
Un posible framework global (`~/.config/opencode/`) y los recursos remotos
de OpenRouter (presets) son iniciativas separadas; ver sección 9.

## 2. Decisiones cerradas

| Tema | Decisión |
|---|---|
| Runtime | OpenCode 1.18.14 (verificado con `opencode --version`) |
| Config | `opencode.jsonc` versionado + `.opencode/` versionado |
| Agente por defecto | `cep`, coordinador que no implementa |
| Delegación | Un nivel (`subagent_depth: 1`); especialistas hoja con `task: deny` |
| Modelos | Routing nativo por agente (`model` en frontmatter), IDs verificados contra el catálogo live de OpenRouter el 2026-08-06. Sin presets |
| MCP OpenTofu | Endpoint remoto oficial `https://mcp.opentofu.org/mcp` (verificado 200 + tools/list) |
| Privacidad | `share: "disabled"` |
| Idioma | Prompts/estándares en inglés; docs en español; respuesta en el idioma del usuario |
| Legacy Kilo/Claude | Retiro solo tras paridad validada y aprobación explícita |

## 3. Arquitectura

```text
Usuario
  -> cep (primary: clasifica, delega, aplica gates, sintetiza)
       -> planner                (read-only)
       -> cloud-architect        (read-only, MCP OpenTofu)
       -> iac-engineer           (edita HCL/docs; MCP; debugging integrado)
       -> software-engineer      (scripts/código auxiliar)
       -> documentation-engineer (solo Markdown/Mermaid)
       -> reviewer               (read-only; MCP)
       -> security-reviewer      (read-only; MCP)
       -> explore                (built-in)

  Inactivos en Phase 1 (fuera de la allowlist de cep, invocables por comando):
       -> devops-engineer
       -> kubernetes-engineer
```

Routing contextual: LLM-driven desde las descripciones de subagentes.
Routing determinista: comandos `/cep-*` con `agent` + `subtask: true`.
Los comandos no fijan modelo para evitar dos fuentes de verdad.

## 4. Estructura implementada

```text
xancloud-iac/
├── AGENTS.md                          # Autoridad única del proyecto
├── opencode.jsonc                     # Config compartida versionada
├── .opencode/
│   ├── agents/
│   │   ├── cep.md                     # Único primary CEP
│   │   ├── planner.md
│   │   ├── cloud-architect.md
│   │   ├── iac-engineer.md            # Incluye flujo de debugging
│   │   ├── software-engineer.md
│   │   ├── documentation-engineer.md
│   │   ├── reviewer.md
│   │   ├── security-reviewer.md
│   │   ├── devops-engineer.md         # Inactivo en Phase 1
│   │   └── kubernetes-engineer.md     # Inactivo en Phase 1
│   ├── commands/
│   │   ├── cep-plan.md
│   │   ├── cep-architect.md
│   │   ├── cep-iac.md
│   │   ├── cep-debug-iac.md
│   │   ├── cep-review.md
│   │   ├── cep-security-review.md
│   │   ├── cep-code.md
│   │   ├── cep-docs.md
│   │   ├── cep-devops.md
│   │   └── cep-kubernetes.md
│   └── skills/
│       └── cep-standards/
│           ├── SKILL.md               # Progressive disclosure
│           └── references/
│               ├── architecture.md
│               ├── terraform-opentofu.md
│               ├── security.md
│               ├── documentation.md
│               └── brand-voice.md     # Migrada desde .claude/rules/
└── plans/
    └── opencode-agent-framework.md    # Este documento
```

## 5. Permisos

OpenCode aplica **last matching rule wins**: catch-all primero, excepciones
después. Configuración base en `opencode.jsonc`:

- `edit: ask`, `bash *: ask`, `external_directory: ask`.
- Denegado explícitamente: `terraform`, `tofu apply|destroy|import|state|force-unlock`,
  `git push`, `gh release create`, `rm -rf`, `sudo`, `aws *` (base).
- Lectura denegada: `.env*`, `*.pem`, `*.key`, claves SSH, `*.tfstate*`,
  credenciales AWS.
- `opentofu_*` (tools del MCP): deny base; allow solo en `iac-engineer`,
  `cloud-architect`, `reviewer`, `security-reviewer`.

Overrides por agente (verificados con `opencode debug agent`):

| Agente | edit | bash | task | MCP |
|---|---|---|---|---|
| cep | deny | deny | allowlist (sin devops/kubernetes) | deny |
| planner | deny | solo inspección | deny | deny |
| cloud-architect | deny | solo inspección | deny | allow |
| iac-engineer | `.tf/.hcl/README módulos/docs/AGENTS/CHANGELOG` | tofu fmt/validate/plan/show/init/test + git/AWS read-only | deny | allow |
| software-engineer | `scripts/**, *.py/.sh/.ts/.go` | ask + denies | deny | deny |
| documentation-engineer | `**/*.md, **/*.mmd` | solo inspección | deny | deny |
| reviewer | deny | solo inspección | deny | allow |
| security-reviewer | deny | solo inspección | deny | allow |
| devops-engineer | `.github/**, Dockerfile, compose, pre-commit` | checks locales; push/release deny | deny | deny |
| kubernetes-engineer | `k8s/**, charts/**, manifests/**` | kubectl read-only; apply/delete deny | deny | deny |

## 6. Mapeo Kilo/Claude → OpenCode (paridad)

| Origen legacy | Destino OpenCode |
|---|---|
| `iac-generator` (.kilocodemodes) | `iac-engineer` |
| `iac-reviewer` | `reviewer` + `security-reviewer` |
| `iac-architect` | `cloud-architect` |
| `iac-debugger` | `iac-engineer` (flujo de debugging) + `/cep-debug-iac` |
| `.kilocode/mcp.json` (`npx -y` sin versión) | `opencode.jsonc` → MCP remoto oficial |
| `.kilo/kilo.json` (solo schema) | Descartado |
| `.kilo/plans/pre-deploy-audit-fixes.md` | No migrado (histórico, fuera del runtime) |
| `.claude/CLAUDE.md` | Duplicado de AGENTS.md → descartado |
| `.claude/CLAUDE.local.md` | Reglas únicas migradas a AGENTS.md (no-atribución IA, labs en `scratch/`) |
| `.claude/rules/git-conventions.md` | Duplicada en AGENTS.md → descartada |
| `.claude/rules/hcl-conventions.md` | Duplicada en AGENTS.md → descartada |
| `.claude/rules/brand-voice.md` | `cep-standards/references/brand-voice.md` |
| `.claude/settings*.json` | Traducción manual restrictiva a `permission` (no literal) |
| `.claude/references/README.md` | Descartado (copia obsoleta del README raíz) |
| `.claude/skills/` (vacío) | Descartado |
| `.kilo/` + `.kilocode/` node_modules, lockfiles | No migrados (dependencias generadas) |

## 7. Validación ejecutada

```bash
opencode --version          # 1.18.14
opencode debug config       # sin ConfigInvalidError
opencode agent list         # cep (primary) + 9 especialistas; sin iac-* legacy
opencode debug agent <name> # permisos resueltos por agente (ver tabla sección 5)
```

MCP: `initialize` y `tools/list` contra `https://mcp.opentofu.org/mcp`
responden correctamente (`@opentofu/opentofu-mcp-server` 1.0.1).

## 8. Pendiente

1. **OpenRouter Presets (opcional, no bloqueante).** El routing de modelos
   ya funciona de forma nativa (`model` por agente). Los presets solo
   aportarían fallbacks automáticos y gestión centralizada. Si se quieren
   adoptar: spike previo de `openrouter/@preset/<slug>` (respuesta normal,
   tool call, modelo efectivo, ZDR) y autorización explícita para crear
   recursos remotos. Sin presets no hay fallback por agente: si un modelo
   cae, se cambia el frontmatter y se commitea.
2. **Smoke tests de routing en vivo** tras reiniciar OpenCode:
   - Diseñar landing zone → cloud-architect, sin edits.
   - Cambiar variable OpenTofu → iac-engineer + reviewer.
   - Modificar IAM → añade security-reviewer.
   - Diagnosticar `tofu plan` → flujo de debugging.
   - Actualizar runbook → documentation-engineer.
   - Solicitar EKS → conflicto Phase 1 detectado, no implementado.
   - Consulta MCP de un recurso AWS conocido desde agente autorizado.
   - Verificación negativa: agente no autorizado sin acceso a `opentofu_*`.
3. **Retiro legacy** (tras aprobación explícita): `.kilocodemodes`,
   `.kilocode/`, `.kilo/`, `.claude/` y sus exclusiones en `.gitignore`.
4. **Reinicio de OpenCode** para cargar la configuración nueva.

## 9. Fuera de alcance (iniciativas separadas)

- Framework global en `~/.config/opencode/` (ya existe una constitución y
  agentes globales independientes de este repo; convergencia futura).
- Presets remotos de OpenRouter y scripts de sincronización.
- Harness de evaluación de agentes (smoke evals automatizados).
- Nuevos módulos IaC, CI/CD, Checkov, `tofu test` (Phase 2 del proyecto).

## 10. Rollback

Restaurar desde Git: `opencode.jsonc`, `.opencode/`, `AGENTS.md` y docs son
archivos versionados o nuevos; retirarlos devuelve el estado anterior. Los
archivos legacy ignorados (`.kilo/`, `.kilocode/`, `.claude/`,
`.kilocodemodes`) permanecen intactos hasta su retiro aprobado. No usar
`git reset --hard` ni `git checkout --` sobre cambios no relacionados.
