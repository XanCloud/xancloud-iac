# Documentation Standard

Extends AGENTS.md for documentation work. AGENTS.md wins on conflict.

## Language rules

| Location | Language |
|---|---|
| `docs/`, plans | Spanish |
| READMEs (root, modules, blueprints) | English |
| Code, comments, commits, changelogs | English |
| User-facing/marketing content | Spanish + brand voice (see brand-voice.md) |

## Document types and their bar

- **Module README**: what it creates, usage snippet, key variables/outputs.
  Brief and manual in Phase 1 (no terraform-docs yet).
- **docs/PROJECT|PHASE|DECISIONS|RISKS**: narrative context; decisions
  include alternatives rejected and why.
- **Runbooks** (docs/DEPLOYMENT.md, TROUBLESHOOTING.md): imperative,
  copy-pasteable commands, expected output or failure signals.
- **Diagrams**: Mermaid only (repo convention). No ASCII diagrams in new
  docs.

## Accuracy controls

Each control is **required or explicitly justified as not applicable**:

- [ ] Every command in the doc was verified or is marked unverified
- [ ] Every file path mentioned exists
- [ ] Version numbers match versions.tf / pinned providers
- [ ] Phase statements match docs/STATUS.md
- [ ] No documentation of planned features as existing

## Sync rule

If a change alters module scope, interfaces, or structure, the context docs
(AGENTS.md, STATUS, ARCHITECTURE, TROUBLESHOOTING as applicable) are
updated in the SAME commit. A doc-only change never silently contradicts
code.
