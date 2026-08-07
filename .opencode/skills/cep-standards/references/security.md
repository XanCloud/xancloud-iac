# Security Standard

Extends AGENTS.md security rules into review controls. AGENTS.md wins on
conflict. Every control is **required or explicitly justified as not
applicable**.

## IAM

- [ ] Least privilege: actions and resources scoped; every `*` has a
      justifying comment
- [ ] Trust policies: principals pinned; no `*` principals; `sts:ExternalId`
      or confused-deputy mitigation where third parties assume roles
- [ ] No privilege-escalation paths (`iam:PassRole` scoped, no
      `iam:*` on `*`)
- [ ] Policy documents via `aws_iam_policy_document`, never inline JSON

## Encryption

- [ ] At-rest encryption on every data-bearing resource (KMS CMK preferred)
- [ ] Key rotation enabled on CMKs
- [ ] Cross-account key access explicit in key policy
- [ ] In-transit enforced (bucket policies denying non-TLS, etc.)

## Secrets

- [ ] No secrets in code, tfvars, outputs, or state-exposed attributes
- [ ] Sensitive outputs marked `sensitive = true`
- [ ] No long-lived credentials in pipelines (OIDC when CI/CD arrives)

## Network

- [ ] No `0.0.0.0/0` ingress without explicit justification
- [ ] Public exposure is opt-in and documented
- [ ] Security group egress reviewed, not defaulted open

## State backend

- [ ] Public access block: all four flags true
- [ ] Bucket policy least-privilege (bootstrap lockout pitfall — see
      AGENTS.md and docs/TROUBLESHOOTING.md)
- [ ] Versioning + encryption on state bucket

## Supply chain

- [ ] Providers pinned (`~>` on minor, per versions.tf template)
- [ ] No external modules from unverified sources
- [ ] No mutable references (`latest`, branch heads) in any dependency

## Verdict rule

Any Critical, or Important without mitigation → Rejected. Findings cite
file:line, attack scenario, and evidence.
