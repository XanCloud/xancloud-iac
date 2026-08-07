# OpenTofu / Terraform Standard

Extends AGENTS.md for non-trivial HCL work. AGENTS.md wins on conflict.
Project binary: `tofu`. NEVER `terraform`.

## Schema verification

- Verify every resource type, argument, and attribute via the OpenTofu MCP
  tools or the official provider docs for the PINNED version
  (`hashicorp/aws ~> 6.0`).
- Provider-major upgrades: read the upgrade guide first; list breaking
  changes affecting current modules before proposing the bump.

## State discipline

- State mutations (`import`, `state mv/rm`, `force-unlock`) are denied at
  the permission layer. If a fix requires one, document the exact commands
  for the user to run — never work around the denial.
- Backend changes are destructive-adjacent: always plan the migration path
  (state pull, backup, re-init) before touching backend config.

## Debugging methodology

1. Reproduce with the smallest command (`tofu validate` → `tofu plan`).
2. Read the FULL error; provider errors point at the real argument ~90%
  of the time.
3. Check the schema via MCP for the exact attribute path.
4. Distinguish: code error vs. state drift vs. provider bug vs.
  permissions (AWS IAM) failure.
5. Minimal fix; explain root cause in one paragraph.

Common project pitfalls are in AGENTS.md "Known LLM Pitfalls" and
docs/TROUBLESHOOTING.md — check both BEFORE proposing a fix. New gotchas
found during debugging go into docs/TROUBLESHOOTING.md in the same change.

## Change discipline

- Minimal diff: no unrequested refactors, formatting sweeps, or renaming.
- Interface changes (variables/outputs) trigger context-doc sync in the
  same change (AGENTS.md rule).
- `for_each` over maps for collections with identity; `count` only for
  simple enable/disable.
