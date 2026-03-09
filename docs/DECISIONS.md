# Decisiones de arquitectura y proceso

Registro de decisiones importantes (ADR-light). Formato: contexto, decisión, consecuencias.

---

## ADR-001: OpenTofu en lugar de Terraform

- **Contexto**: Necesidad de IaC estable, compatible con ecosistema Terraform, sin dependencia de licencia BSL de HashiCorp.
- **Decisión**: Usar OpenTofu ≥ 1.11.0 como binario estándar. Comandos vía `tofu`, no `terraform`.
- **Consecuencias**: Compatibilidad con módulos y providers del ecosistema; lockfile y state con formato estándar. CI y documentación deben referenciar `tofu`.

---

## ADR-002: AWS como cloud principal

- **Contexto**: Proyecto orientado a consultoría AWS; MVP acotado a un proveedor.
- **Decisión**: AWS como única nube en el MVP. AWS Provider ~> 5.0.
- **Consecuencias**: Patrones (IAM, S3, KMS, CloudTrail) son específicos de AWS. Multi-cloud sería fase posterior.

---

## ADR-003: Estructura modules / blueprints / environments

- **Contexto**: Separar módulos reutilizables de composiciones (blueprints) y de instancias por entorno.
- **Decisión**: `modules/` para módulos atómicos; `blueprints/` para composiciones (p. ej. landing-zone-basic); `environments/{dev,prod}/` para roots por entorno.
- **Consecuencias**: Claridad en dónde vivirán variables y state por entorno; blueprints llaman a módulos vía source local o registry.

---

## ADR-004: State remoto S3 + KMS + lockfile

- **Contexto**: State debe estar cifrado y bloqueado para trabajo en equipo.
- **Decisión**: Módulo state-backend con S3, DynamoDB (lock), KMS. Uso de `use_lockfile` donde el provider/versión lo permita.
- **Consecuencias**: Primer despliegue puede ser bootstrap manual o script; el resto de entornos usan backend remoto.

---

*(Otras decisiones se irán añadiendo en Phase 1 según implementación.)*
