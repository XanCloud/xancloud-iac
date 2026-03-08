# Fase 4 — Operaciones Día 2

> **Duración estimada:** 2-3 semanas | **Dependencia:** Fase 1 completa | **Estado:** No iniciada  
> **Nota:** Ejecutable en paralelo con Fases 2 y 3.

## Objetivo

Cubrir el ciclo de vida post-despliegue: drift detection, cost monitoring, backup/DR y alerting sobre cambios no autorizados.

## Entregables

- Pipeline `drift-detect.yml` mejorado — Notificación a Slack/email con diff detallado
- Módulo `operations/cost-mgmt/` — AWS Budgets, Cost Anomaly Detection, dashboards
- Módulo `operations/backup/` — AWS Backup policies con restore testing programado
- Runbooks operativos — Procedimientos documentados para incidentes comunes
- Dashboard de estado — CloudWatch dashboard consolidado por entorno

## Criterio de completitud

- [ ] Drift detection notifica en < 5 min después de detectar cambio
- [ ] Budgets configurados con alertas al 80% y 100%
- [ ] Backup policy con restore test documentado y exitoso
- [ ] Al menos 5 runbooks escritos (drift, cost spike, security finding, backup restore, access review)
