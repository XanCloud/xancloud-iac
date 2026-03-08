---
name: xancloud-iac-blueprint
description: >
  Genera blueprints que componen múltiples módulos del proyecto xancloud-iac usando OpenTofu.
  Trigger cuando se trabaje en blueprints/, se mencionen composiciones de módulos, landing zone,
  "juntar módulos", patrones de workload, tfvars por entorno, backend config, o se pida crear
  un blueprint nuevo. También trigger cuando se pregunte cómo conectar módulos entre sí,
  cómo pasar outputs de un módulo como inputs de otro, cómo estructurar environments/,
  o se trabaje en archivos de entorno (dev/, staging/, prod/). Trigger para cualquier
  discusión sobre cómo componer la infraestructura completa a partir de módulos individuales.
---

# XanCloud IaC — Blueprint Composition Patterns

## Qué es un blueprint

Una composición opinada que conecta múltiples módulos con defaults por entorno. No contiene recursos propios — solo `module` blocks, variables de composición, y outputs agregados.

## Estructura

```
blueprints/{name}/
├── main.tf          # module blocks que componen los módulos
├── variables.tf     # Variables de composición (no repiten las de módulos)
├── outputs.tf       # Outputs agregados
├── versions.tf      # required_providers
├── locals.tf        # Defaults por entorno, lógica de composición
├── backend.tf       # Backend config (parcial, completado por -backend-config)
└── README.md        # Auto-generado

environments/
├── dev/
│   ├── terraform.tfvars
│   └── backend.hcl
├── staging/
│   ├── terraform.tfvars
│   └── backend.hcl
└── prod/
    ├── terraform.tfvars
    └── backend.hcl
```

## Patrones de composición

### Module source

Paths relativos para desarrollo local, registry/OCI para distribución:

```hcl
# Desarrollo local (path relativo)
module "example" {
  source = "../../modules/{category}/{name}"
}

# Distribución (GitHub release)
module "example" {
  source = "git::https://github.com/xancloud/xancloud-iac.git//modules/{category}/{name}?ref=v1.0.0"
}

# Distribución (OCI registry)
module "example" {
  source  = "oci://ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/xancloud/{name}"
  version = "1.0.0"
}
```

Usar path relativo hasta que los módulos estén publicados en registry.

### Variables comunes propagadas

Todo blueprint propaga las 4 variables comunes a cada módulo que compone:

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  type        = string
}

variable "owner" {
  type        = string
}

variable "cost_center" {
  type        = string
}
```

Cada `module` block recibe estas 4 variables. Sin excepciones.

### Defaults por entorno

Patrón para diferenciar comportamiento entre entornos sin duplicar blueprints:

```hcl
locals {
  env_defaults = {
    dev     = { /* valores opinados */ }
    staging = { /* valores opinados */ }
    prod    = { /* valores opinados */ }
  }

  defaults = local.env_defaults[var.environment]
}
```

Los módulos consumen con `lookup()` para fallback seguro:

```hcl
module "example" {
  source       = "../../modules/{category}/{name}"
  some_setting = lookup(local.defaults, "some_setting", "fallback_value")
}
```

Los defaults son el baseline opinado. El tfvars del entorno es la personalización.

### Backend parcial

El blueprint declara el backend sin configurar. La configuración viene del entorno:

```hcl
# backend.tf (en blueprint)
terraform {
  backend "s3" {}
}
```

```hcl
# environments/{env}/backend.hcl
bucket       = "{project}-{env}-state"
key          = "{blueprint-name}/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
```

```bash
tofu init -backend-config=../../environments/dev/backend.hcl
tofu plan -var-file=../../environments/dev/terraform.tfvars
```

Cada blueprint tiene su propia `key` en el state. No compartir state entre blueprints.

### Wiring entre módulos

Outputs de un módulo alimentan inputs de otro. Este es el valor real del blueprint:

```hcl
module "a" {
  source = "../../modules/category/a"
}

module "b" {
  source        = "../../modules/category/b"
  dependency_id = module.a.resource_id  # output de A → input de B
}
```

Reglas:
- Nunca hardcodear IDs o ARNs entre módulos. Siempre usar outputs.
- Con `for_each`, referenciar con la key: `module.vpc["main"].vpc_id`.
- Si hay dependencia circular, el diseño de módulos está mal — refactorizar.

### for_each en composiciones

Para módulos instanciados múltiples veces:

```hcl
variable "vpcs" {
  type = map(object({
    cidr       = string
    azs        = number
    single_nat = bool
  }))
}

module "vpc" {
  source   = "../../modules/networking/vpc"
  for_each = var.vpcs

  cidr       = each.value.cidr
  azs        = each.value.azs
  single_nat = each.value.single_nat
}
```

Usar `for_each` sobre maps con keys descriptivas (`"main"`, `"isolated"`), nunca `count`.

### Módulos con toggle

Módulos que pueden habilitarse/deshabilitarse por entorno:

```hcl
module "optional_service" {
  source  = "../../modules/category/name"
  enabled = local.defaults.service_enabled
}
```

El módulo internamente usa `count = var.enabled ? 1 : 0`. El blueprint solo pasa el toggle.

### Outputs agregados

Exponer outputs seleccionados, no passthrough de todo:

```hcl
output "vpc_ids" {
  description = "Map of VPC name to VPC ID"
  value       = { for k, v in module.vpc : k => v.vpc_id }
}
```

## Checklist

- [ ] Solo `module` blocks, sin recursos propios
- [ ] Backend parcial con `-backend-config`
- [ ] Defaults por entorno en `locals.tf`
- [ ] Variables comunes (environment, project, owner, cost_center) en todos los módulos
- [ ] Wiring via outputs (sin IDs/ARNs hardcoded)
- [ ] Outputs agregados con `description`
- [ ] `for_each` sobre maps (no `count`) para colecciones
- [ ] tfvars de ejemplo por entorno
- [ ] `use_lockfile = true` en backend.hcl
- [ ] Cada blueprint con `key` única en state
