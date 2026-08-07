# Architecture Standard

Extends AGENTS.md for design work. AGENTS.md wins on conflict.

## Decision hierarchy (apply explicitly, in order)

1. Security
2. Cost-efficiency
3. High availability
4. Resilience
5. Operability

Every design document states which layers were traded and why. A trade of
a higher layer for a lower one requires explicit user approval — always
flag it.

## Business context (xancloud-iac)

- Target: SMBs in LATAM, <$1K/month AWS spend.
- Single AWS account; environment separation via tags.
- Solo founder, ~10-15h/week — operability burden is a real cost.

## Design review controls

Each control is **required or explicitly justified as not applicable**:

- [ ] Blast radius stated (what breaks if this component fails)
- [ ] Cost driver identified (per-month order of magnitude)
- [ ] Recovery path exists (backup, recreate-from-IaC, or accepted loss)
- [ ] Data classification stated (public / internal / sensitive)
- [ ] Failure mode under AZ loss considered
- [ ] Operational runbook need identified (or justified N/A)
- [ ] Composition uses existing module interfaces, not new coupling

## Composition rules

- Reference existing modules by their documented outputs (see
  docs/ARCHITECTURE.md dependency map).
- New cross-module data flow = architecture decision; document it in
  docs/DECISIONS.md as an ADR-style entry.
- No transitive module nesting beyond blueprint → module.

## Output contract

Architecture, Decisions, Trade-offs, Risks, Costs, Recommendation —
one prescriptive recommendation, never a menu of maybes.
