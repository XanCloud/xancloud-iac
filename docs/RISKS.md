# Riesgos y mitigaciones

Registro de riesgos identificados y medidas de mitigación.

---

## R1: Dependencia de un solo mantenedor (bus factor = 1)

- **Impacto**: Alto si no hay documentación ni convenciones claras.
- **Mitigación**: Documentación en `docs/`, convenciones en skills/rules, PR templates y checklist. Fase 2 añade CI que obliga a fmt/validate.

---

## R2: Cambios de breaking en AWS Provider o OpenTofu

- **Impacto**: Plan/apply fallidos o comportamientos no esperados.
- **Mitigación**: Fijar versiones (OpenTofu ≥ 1.11, AWS ~> 5.0). Lockfile en repo. Probar upgrades en entorno dev antes de prod.

---

## R3: State corrupto o pérdida de state

- **Impacto**: Pérdida de trazabilidad o necesidad de reimportación.
- **Mitigación**: State en S3 con versionado habilitado; backups de bucket si la política organizativa lo exige. Evitar state local en producción.

---

## R4: Secretos en código o en state

- **Impacto**: Compromiso de credenciales o datos sensibles.
- **Mitigación**: No generar IAM Users; solo roles (OIDC/AssumeRole). Variables sensibles vía env o backend, nunca en .tf ni .tfvars en repo. Pre-commit y CI con detect-private-key; Phase 2 con Checkov.

---

## R5: Alcance MVP insuficiente para primeros clientes

- **Impacto**: Rechazo o retrabajo.
- **Mitigación**: Phase 0 valida mensaje y alcance; Phase 1 entrega solo 4 módulos + 1 blueprint con criterios de salida claros. Iterar con feedback real antes de Phase 2.

---

*(Nuevos riesgos se añadirán según avance el proyecto.)*
