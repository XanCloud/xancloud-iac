# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- OpenCode agent framework (versioned): `opencode.jsonc` + `.opencode/` with `cep` coordinator, 9 specialists, `/cep-*` commands, and `cep-standards` skill (on-demand standards)
- Remote OpenTofu MCP (`https://mcp.opentofu.org/mcp`) restricted by role via permissions
- AGENTS.md: AI-attribution prohibition, labs-in-`scratch/` rule, OpenCode tooling section
- `plans/opencode-agent-framework.md` — replaces the Kilo-based CEP plan
- Module `networking/vpc`: Multi-VPC with public/private subnets, NAT GWs, route tables, VPC endpoints (gateway + interface), flow logs to CloudWatch or S3
- Module `state-backend`: S3 + KMS for remote state (bootstrap-first, native S3 locking)
- Initial project scaffold with directory structure
- Project documentation (PROJECT.md, phases, decisions, risks)
- Repository configuration (.gitignore, .editorconfig, pre-commit, PR/issue templates)

### Changed
- `.gitignore` now versions OpenCode config (`.opencode/`, `opencode.jsonc`)
- Agent models: native per-agent routing via `model` frontmatter, cost-optimized mapping (deepseek-v4-pro/flash, kimi-k3 for architect + security-reviewer, haiku-4.5 for docs); IDs and pricing verified against live OpenRouter catalog; OpenRouter Presets demoted to optional, non-blocking

### Removed
- `plans/cep-agent-framework.md` (Kilo plan, superseded)
