# Phase 2 — Industrialización

## Objetivo

Añadir calidad, seguridad y repetibilidad al proyecto: CI/CD, políticas, tests y documentación automática. Solo se activa cuando exista (o esté comprometido) un primer cliente o uso interno estable.

## Entregables previstos

- **CI/CD**: GitHub Actions para `tofu fmt`, `tofu validate`, y opcionalmente `tofu plan` en PR.
- **Policy**: Checkov ≥ 3.2.x y/o OPA/Rego para reglas de seguridad y estándares.
- **Testing**: `tofu test` donde aplique; Terratest para integración si se justifica.
- **Docs**: Hook `tofu_docs` / terraform-docs en pre-commit; README generados por módulo.
- **Examples**: Carpetas `examples/` en módulos donde aporten valor.

## Dependencias

- Repo estable con al menos un entorno aplicado (dev o prod).
- Definición de reglas de policy (Checkov/OPA) alineadas con estándares del proyecto.

## Criterios de salida

- Pipelines verdes en main para fmt/validate.
- Sin secretos en código; políticas ejecutadas en CI.
- Changelog y versionado claros para entregas.
