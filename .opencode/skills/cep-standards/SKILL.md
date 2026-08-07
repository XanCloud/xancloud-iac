---
name: cep-standards
description: Use when implementing, reviewing, or documenting xancloud-iac work that needs standards beyond AGENTS.md — architecture trade-offs, OpenTofu/Terraform advanced patterns, security review checklists, documentation conventions, or XanCloud brand voice. Load only the reference files relevant to the task.
---

# CEP Standards — Progressive Disclosure

AGENTS.md is the single authority for project rules. These references add
depth for specialist tasks WITHOUT duplicating AGENTS.md. If a rule here
contradicts AGENTS.md, AGENTS.md wins — report the drift.

## How to use

Load ONLY the references applicable to your current task. Each control is
**required or explicitly justified as not applicable** — never silently
skipped.

| Reference | Load when | Primary agents |
|---|---|---|
| `references/architecture.md` | Design decisions, trade-off analysis, NFR review | cloud-architect, planner |
| `references/terraform-opentofu.md` | Non-trivial HCL work, debugging, state questions | iac-engineer, reviewer |
| `references/security.md` | Security review, IAM/KMS/network/state changes | security-reviewer, reviewer |
| `references/documentation.md` | Writing docs, READMEs, runbooks, diagrams | documentation-engineer |
| `references/brand-voice.md` | User-facing or marketing-adjacent content | documentation-engineer |

## Rules

- Do not load all references by default — context is a budget.
- Do not restate these standards in prompts or docs; reference them.
- Standards evolve here, in one place, in English (except brand-voice,
  which is Spanish content by nature).
