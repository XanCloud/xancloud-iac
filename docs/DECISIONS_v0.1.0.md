# Decisiones de Diseño

Cada decisión tiene su trade-off documentado. Si una decisión se revierte, se documenta aquí con fecha y razón.

| # | Decisión | Elección | Trade-off | Fecha |
|---|---|---|---|---|
| 1 | IaC Tool | OpenTofu sobre Terraform | Libertad comercial total. Se pierde Terraform Cloud (Sentinel, remote runs). | 2026-03 |
| 2 | Single account MVP | Tags en vez de Organizations | Más rápido. Sin blast radius isolation real entre entornos. Aceptable para MVP. | 2026-03 |
| 3 | VPC por entorno | Sin Transit Gateway | ~$36/mes menos. Sin conectividad inter-VPC. Se agrega en Fase 2. | 2026-03 |
| 4 | NAT Gateway | Single en dev/staging, per-AZ en prod | ~$32/mes ahorro por NAT omitido. Dev/staging no son HA en egress. | 2026-03 |
| 5 | State backend | S3 native locking (sin DynamoDB) | Requiere OpenTofu >= 1.10. Simplifica infra y reduce costo. | 2026-03 |
| 6 | CI/CD | GitHub Actions sobre Azure DevOps | Portfolio visible. Menor integración con boards. Migración a AzDO documentada. | 2026-03 |
| 7 | Policy engine | Checkov + OPA sobre Sentinel | Open source, sin lock-in. Mayor complejidad de setup inicial. | 2026-03 |
| 8 | Registry | Dual: GitHub + OCI | Mayor complejidad operativa. Necesario para separar open-source de clientes. | 2026-03 |
| 9 | Security services | enabled = false por defecto (excepto CloudTrail) | No se paga en entornos de prueba. Riesgo: olvidar habilitar en prod. Mitigación: Checkov check custom. | 2026-03 |
| 10 | VPCs por entorno | Map iterable con for_each | Flexible para N VPCs. Decision tree documenta cuándo se justifica más de 1. | 2026-03 |
