# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Module `state-backend`: S3 + KMS for remote state with native S3 locking (bootstrap-first)
- Module `networking/vpc`: Multi-VPC with public/private subnets, NAT GWs, route tables, VPC endpoints (gateway + interface), flow logs to CloudWatch or S3
- Module `security/cloudtrail`: Multi-region trail with dedicated S3 bucket, KMS encryption, Object Lock, optional CloudWatch Logs delivery
- Module `identity/iam-baseline`: Account-level hardening (S3 Block Public Access, IAM password policy, Access Analyzer, IMDSv2 defaults, optional account alias)
- Blueprint `landing-zone-basic`: Composition of all 4 modules with dev/prod environment examples
- Initial project scaffold with directory structure
- Project documentation (PROJECT.md, phases, decisions, risks)
- Repository configuration (.gitignore, .editorconfig, pre-commit, PR/issue templates)
