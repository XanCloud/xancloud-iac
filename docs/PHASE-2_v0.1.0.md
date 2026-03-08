# Fase 2 — Multi-Account

> **Duración estimada:** 3-4 semanas | **Dependencia:** Fase 1 completa | **Estado:** No iniciada

## Objetivo

Evolucionar de single-account con tags a una estrategia multi-account con AWS Organizations, SCPs y conectividad cross-account.

## Entregables

- Módulo `organizations/` — AWS Organizations con OUs (Security, Workloads, Sandbox)
- Módulo `scp/` — Service Control Policies base (deny regions, deny root access, require tags)
- Módulo `networking/transit-gateway/` — Hub-spoke para conectividad inter-VPC cross-account
- Actualización de `identity/sso` — Reasignar permission sets a OUs
- Actualización de `state-backend` — Mover a cuenta dedicada de tooling
- Blueprint `landing-zone-org/` — Composición multi-account completa

## Decisiones pendientes

- ¿Control Tower como base o Organizations raw? (Control Tower es más rápido pero menos flexible)
- ¿Cuenta de log archive separada o consolidada con security?
- ¿Cuántas OUs iniciales? Mínimo viable: Security, Workloads, Sandbox
- ¿Transit Gateway desde el inicio o solo VPC Peering para empezar?

## Criterio de completitud

- [ ] Organización funcional con al menos 3 cuentas (management, security, workload)
- [ ] SCPs aplicadas y testeadas
- [ ] Conectividad cross-account funcional
- [ ] Pipeline despliega en múltiples cuentas con roles cross-account
