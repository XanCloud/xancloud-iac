---
name: xancloud-iac-testing
description: >
  Genera archivos de test para módulos del proyecto xancloud-iac usando OpenTofu (NO Terraform).
  Trigger cuando se mencione testing, tests, "tofu test", Terratest, validación de módulos,
  ".tftest.hcl", test suites, mocks, assertions, mock providers, o se pida crear, editar o
  revisar tests para cualquier módulo HCL. También trigger cuando se pregunte cómo testear
  un módulo, qué assertions usar, cómo estructurar tests, o se trabaje en archivos dentro
  de tests/ o en archivos .tftest.hcl. Trigger incluso para preguntas sobre estrategia
  de testing en IaC — el proyecto tiene convenciones específicas para esto.
---

# XanCloud IaC — Test Generator

## Stack de testing

| Herramienta | Uso | Cuándo |
|---|---|---|
| `tofu test` | Validación rápida con mock providers | CI en cada PR. Tests unitarios. |
| Terratest (Go) | Integración con recursos reales de AWS | Pre-release, scheduled. Tests de integración. |

## tofu test — Convenciones

### Ubicación

Tests viven en `modules/{category}/{name}/tests/`:

```
modules/networking/vpc/tests/
├── basic.tftest.hcl          # Caso mínimo funcional
├── multi_az.tftest.hcl       # Variantes de configuración
└── validation.tftest.hcl     # Tests de validation blocks
```

### Estructura de un .tftest.hcl

```hcl
# tests/basic.tftest.hcl

mock_provider "aws" {}

variables {
  environment  = "dev"
  project      = "xancloud-test"
  owner        = "platform-team"
  cost_center  = "CC-TEST"
  # ... variables específicas del módulo
}

run "creates_vpc_with_correct_tags" {
  command = plan

  assert {
    condition     = aws_vpc.this.tags["Environment"] == "dev"
    error_message = "VPC must have Environment tag set to dev"
  }

  assert {
    condition     = aws_vpc.this.tags["ManagedBy"] == "opentofu"
    error_message = "VPC must have ManagedBy tag set to opentofu"
  }
}

run "validates_cidr_block" {
  command = plan

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR must match input variable"
  }
}
```

### Patrones clave

**command = plan vs apply:**
- `plan` — para tests unitarios con mock providers. Rápido, sin recursos reales. Usar por defecto.
- `apply` — solo cuando se necesita verificar comportamiento post-apply (outputs reales, data sources).

**mock_provider:**
- Siempre `mock_provider "aws" {}` para tests unitarios.
- Para módulos que usan múltiples providers, mockear todos.
- No usar `override_resource` a menos que el test lo requiera específicamente.

**Variables:**
- Siempre incluir las 4 variables comunes: `environment`, `project`, `owner`, `cost_center`.
- Usar valores de test distinguibles (ej: `project = "xancloud-test"`, `environment = "dev"`).

### Qué testear por tipo de módulo

**Networking (VPC):**
- CIDR block correcto
- Número de subnets = AZs × tipos de subnet
- NAT Gateway count (single vs per-AZ)
- Tags en VPC y subnets
- Flow logs configurados
- VPC endpoints creados

**Security (GuardDuty, SecurityHub, etc.):**
- `enabled = false` → 0 recursos creados
- `enabled = true` → recurso principal existe
- Configuración específica del servicio cuando enabled

**Identity (SSO, IAM baseline):**
- Permission sets creados
- Grupos creados
- Password policy configurada

**State backend:**
- S3 bucket con encryption
- KMS key creada
- Bucket policy restrictiva
- Versionamiento habilitado

### Tests de validation blocks

Testear que las validaciones rechazan inputs inválidos:

```hcl
# tests/validation.tftest.hcl

mock_provider "aws" {}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "invalid"
    project     = "xancloud-test"
    owner       = "platform-team"
    cost_center = "CC-TEST"
  }

  expect_failures = [
    var.environment,
  ]
}

run "rejects_invalid_project_name" {
  command = plan

  variables {
    environment = "dev"
    project     = "UPPERCASE-BAD"
    owner       = "platform-team"
    cost_center = "CC-TEST"
  }

  expect_failures = [
    var.project,
  ]
}
```

## Terratest — Convenciones

### Ubicación

Tests de integración viven en `tests/integration/`:

```
tests/
└── integration/
    ├── vpc_test.go
    ├── state_backend_test.go
    └── go.mod
```

### Estructura de un test Go

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVpcCreatesSuccessfully(t *testing.T) {
    t.Parallel()

    opts := &terraform.Options{
        TerraformDir:    "../../modules/networking/vpc/examples/simple",
        TerraformBinary: "tofu",
        Vars: map[string]interface{}{
            "environment": "dev",
            "project":     "terratest",
            "owner":       "platform-team",
            "cost_center": "CC-TEST",
        },
    }

    defer terraform.Destroy(t, opts)
    terraform.InitAndApply(t, opts)

    vpcId := terraform.Output(t, opts, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

**Notas críticas:**
- `TerraformBinary: "tofu"` — SIEMPRE. Sin esto, Terratest usa `terraform`.
- `t.Parallel()` — para correr tests en paralelo.
- `defer terraform.Destroy()` — SIEMPRE. Limpiar recursos.
- Tests corren contra `examples/simple/` del módulo, no contra el módulo directo.

## Proceso de generación

Cuando el usuario pida crear tests:

1. Identificar el módulo target.
2. Generar `tests/basic.tftest.hcl` (caso mínimo con mock provider).
3. Generar `tests/validation.tftest.hcl` si el módulo tiene validation blocks.
4. Si se pide Terratest, generar el archivo Go correspondiente.
5. Verificar que todas las variables comunes están incluidas.

## Checklist

- [ ] `mock_provider "aws" {}` en tests unitarios
- [ ] Variables comunes presentes (environment, project, owner, cost_center)
- [ ] Assertions verifican tags obligatorios
- [ ] Tests de validation con `expect_failures`
- [ ] Terratest usa `TerraformBinary: "tofu"`
- [ ] Terratest incluye `defer terraform.Destroy()`
