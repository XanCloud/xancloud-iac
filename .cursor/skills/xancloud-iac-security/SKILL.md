---
name: xancloud-iac-security
description: >
  Genera políticas de seguridad (Checkov custom checks y OPA/Rego) para el proyecto xancloud-iac.
  Trigger cuando se trabaje en policies/, se mencione Checkov custom checks, OPA, Rego, SCPs,
  security baseline, policy-as-code, compliance checks, o se pida crear reglas de validación
  para infraestructura. También trigger cuando se pregunte cómo enforcar tags obligatorios,
  encriptación, public access blocks, o cualquier guardrail de seguridad a nivel de pipeline.
  Trigger para cualquier discusión sobre policies de seguridad en el contexto del proyecto.
---

# XanCloud IaC — Security Policy Generator

## Stack de policies

| Tool | Formato | Uso |
|---|---|---|
| Checkov | YAML o Python | Escaneo estático en CI. Quality gate bloqueante. |
| OPA/Rego | .rego | Policies custom evaluadas contra plan JSON. |

No usar Sentinel (HashiCorp Terraform exclusivo).

## Estructura

```
policies/
├── checkov/
│   ├── custom_checks/
│   │   ├── __init__.py
│   │   ├── mandatory_tags.py
│   │   ├── encryption_at_rest.py
│   │   └── no_public_s3.py
│   └── checkov_config.yml
└── opa/
    ├── mandatory_tags.rego
    ├── encryption.rego
    └── iam_least_privilege.rego
```

## Checkov Custom Checks (Python)

### Patrón base

```python
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult, CheckCategories


class MandatoryTagsCheck(BaseResourceCheck):
    def __init__(self):
        name = "Ensure all resources have mandatory tags"
        id = "XC_TAGS_001"
        supported_resources = ["*"]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories,
                         supported_resources=supported_resources)

    MANDATORY_TAGS = ["Environment", "Project", "Owner", "ManagedBy", "CostCenter"]

    def scan_resource_conf(self, conf):
        tags = conf.get("tags", [{}])
        if isinstance(tags, list):
            tags = tags[0] if tags else {}

        for tag in self.MANDATORY_TAGS:
            if tag not in tags:
                return CheckResult.FAILED
        return CheckResult.PASSED


check = MandatoryTagsCheck()
```

### Naming de checks

- Prefijo: `XC_` (XanCloud).
- Categorías: `XC_TAGS_`, `XC_ENC_`, `XC_IAM_`, `XC_NET_`, `XC_S3_`.
- IDs secuenciales: `XC_TAGS_001`, `XC_ENC_001`, etc.

### Checks del proyecto

| ID | Check | Severidad |
|---|---|---|
| XC_TAGS_001 | Mandatory tags en todos los recursos | 🔴 Critical |
| XC_ENC_001 | Encriptación at-rest en S3, EBS, RDS, SQS, SNS | 🔴 Critical |
| XC_S3_001 | S3 Block Public Access habilitado | 🔴 Critical |
| XC_IAM_001 | Sin wildcard `*` en IAM actions | 🟡 Important |
| XC_IAM_002 | Sin wildcard `*` en IAM resources | 🟡 Important |
| XC_NET_001 | Sin 0.0.0.0/0 en security group ingress | 🟡 Important |
| XC_EC2_001 | IMDSv2 enforced | 🟡 Important |

### checkov_config.yml

```yaml
soft-fail: false
framework:
  - terraform
check:
  - XC_TAGS_001
  - XC_ENC_001
  - XC_S3_001
  - XC_IAM_001
  - XC_IAM_002
  - XC_NET_001
  - XC_EC2_001
external-checks-dir:
  - policies/checkov/custom_checks
output:
  - cli
  - sarif
```

## OPA/Rego Policies

### Patrón base

Las policies OPA evalúan contra el output de `tofu show -json plan.tfplan`:

```rego
# policies/opa/mandatory_tags.rego
package xancloud.tags

import rego.v1

mandatory_tags := ["Environment", "Project", "Owner", "ManagedBy", "CostCenter"]

deny contains msg if {
    resource := input.resource_changes[_]
    resource.change.actions[_] == "create"

    tags := object.get(resource.change.after, "tags", {})
    tag := mandatory_tags[_]
    not tags[tag]

    msg := sprintf("Resource %s is missing mandatory tag: %s", [resource.address, tag])
}
```

### Evaluación en CI

```bash
# En el workflow de GitHub Actions
tofu plan -out=plan.tfplan
tofu show -json plan.tfplan > plan.json
opa eval -i plan.json -d policies/opa/ "data.xancloud" --fail-defined
```

## SCPs (Fase 2+)

Para Fase 2 (multi-account), las SCPs se gestionan como módulos HCL:

```hcl
# modules/scp/deny-regions.tf
resource "aws_organizations_policy" "deny_regions" {
  name        = "deny-unauthorized-regions"
  description = "Deny all regions except allowed ones"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnauthorizedRegions"
        Effect    = "Deny"
        NotAction = ["iam:*", "organizations:*", "sts:*"]
        Resource  = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      }
    ]
  })
}
```

No generar SCPs en Fase 1 — single account, no hay Organizations.

## Checklist

- [ ] Checks con prefijo `XC_` y ID secuencial
- [ ] Checks cubren: tags, encriptación, public access, IAM, networking
- [ ] `soft_fail: false` en Checkov config
- [ ] Rego policies evalúan contra plan JSON (no state)
- [ ] Sin Sentinel (no compatible con OpenTofu)
- [ ] SCPs solo en contexto Fase 2+
