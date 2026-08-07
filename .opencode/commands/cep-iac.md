---
description: Implement or modify OpenTofu modules/blueprints following xancloud-iac conventions (never applies).
agent: iac-engineer
subtask: true
---

Implement the following IaC change. Follow AGENTS.md conventions exactly:
file order, common variables, locals pattern, naming, tagging, encryption,
HCL rules. Verify schemas via the OpenTofu MCP. Run `tofu fmt` and
`tofu validate` when done. NEVER run apply/destroy/state mutations.

$ARGUMENTS
