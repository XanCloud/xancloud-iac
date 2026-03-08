# Riesgos y Mitigaciones

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| OpenTofu no mantiene paridad con providers | Baja | Alto | Providers son independientes del fork. Monitorear releases. |
| Scope creep: features antes de terminar MVP | Alta | Alto | Fase 1 congelada. Todo lo demás va a backlog. |
| Costo de cuenta AWS para testing | Media | Medio | LocalStack para tests unitarios. AWS free tier para integración. |
| Falta de diferenciación vs competidores | Media | Alto | Enfoque LATAM. Documentación bilingüe. Pricing accesible. |
| Deuda técnica por velocidad inicial | Media | Medio | Testing obligatorio desde día 1. No se mergea sin tests. |
