---
name: xancloud-iac-client
description: >
  Genera la estructura de repositorio para un nuevo cliente de XanCloud a partir del template
  client-scaffold/. Trigger cuando se mencione scaffold de cliente, nuevo proyecto para cliente,
  onboarding de cliente, template, personalización de landing zone para un cliente específico,
  o se trabaje en templates/client-scaffold/. También trigger cuando se pregunte cómo
  configurar un repo para un nuevo cliente, cómo personalizar tfvars, backend config,
  o pipeline para un cliente. Trigger ante "nuevo cliente", "scaffold", "onboarding",
  "template de cliente", o cualquier referencia a preparar infraestructura para un cliente nuevo.
---

# XanCloud IaC — Client Scaffold Generator

## Qué genera

Un repositorio completo para un nuevo cliente con:
- Backend config personalizado
- Environments (dev/staging/prod) con tfvars
- Pipeline CI/CD pre-configurado
- Referencia a módulos de xancloud-iac (source remoto)

## Estructura del scaffold

```
templates/client-scaffold/
├── scaffold.sh              # Script de generación
├── template/
│   ├── main.tf.tpl
│   ├── variables.tf.tpl
│   ├── outputs.tf.tpl
│   ├── versions.tf.tpl
│   ├── backend.tf.tpl
│   ├── locals.tf.tpl
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── terraform.tfvars.tpl
│   │   │   └── backend.hcl.tpl
│   │   ├── staging/
│   │   │   ├── terraform.tfvars.tpl
│   │   │   └── backend.hcl.tpl
│   │   └── prod/
│   │       ├── terraform.tfvars.tpl
│   │       └── backend.hcl.tpl
│   ├── .github/
│   │   └── workflows/
│   │       ├── plan.yml.tpl
│   │       └── deploy.yml.tpl
│   ├── .gitignore
│   └── README.md.tpl
└── README.md                # Instrucciones del scaffold
```

## Variables del scaffold

| Variable | Descripción | Ejemplo |
|---|---|---|
| `CLIENT_NAME` | Nombre del cliente (lowercase, hyphens) | `acme-corp` |
| `CLIENT_PROJECT` | Nombre del proyecto | `acme-platform` |
| `AWS_REGION` | Región principal | `us-east-1` |
| `AWS_ACCOUNT_ID` | Account ID del cliente | `123456789012` |
| `STATE_BUCKET` | Nombre del bucket de state | `acme-corp-tf-state` |
| `OIDC_ROLE_ARN` | ARN del role para CI/CD | `arn:aws:iam::role/gha-deploy` |

## Module source en scaffolds

Los scaffolds referencian módulos de xancloud-iac via GitHub releases o OCI:

```hcl
# Fase 1-4: GitHub source
module "vpc" {
  source = "git::https://github.com/xancloud/xancloud-iac.git//modules/networking/vpc?ref=v1.0.0"
  # ...
}

# Fase 5: OCI registry
module "vpc" {
  source  = "oci://ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/xancloud/networking-vpc"
  version = "1.0.0"
  # ...
}
```

## Personalización por cliente

### Mínima (landing zone estándar)
Solo cambiar: nombre, región, account ID, CIDR blocks.

### Media (ajustes de seguridad/networking)
Cambiar: security services enabled/disabled, número de AZs, VPC endpoints, NAT config.

### Alta (requirements específicos)
Agregar: módulos adicionales, policies custom, integraciones específicas. Requiere trabajo de consultoría.

## Script de generación

```bash
#!/bin/bash
# scaffold.sh - Genera repo de cliente

set -euo pipefail

CLIENT_NAME="${1:?Usage: scaffold.sh <client-name>}"
OUTPUT_DIR="${2:-./${CLIENT_NAME}-iac}"

echo "Generating scaffold for: ${CLIENT_NAME}"
echo "Output: ${OUTPUT_DIR}"

# Copiar template
cp -r template/ "${OUTPUT_DIR}/"

# Reemplazar placeholders
find "${OUTPUT_DIR}" -name "*.tpl" | while read file; do
  sed -i \
    -e "s/{{CLIENT_NAME}}/${CLIENT_NAME}/g" \
    -e "s/{{CLIENT_PROJECT}}/${CLIENT_NAME}/g" \
    "${file}"
  mv "${file}" "${file%.tpl}"
done

echo "Scaffold generated. Review and customize:"
echo "  - environments/*/terraform.tfvars"
echo "  - environments/*/backend.hcl"
echo "  - .github/workflows/*.yml"
```

## Checklist

- [ ] Nombre de cliente normalizado (lowercase, hyphens)
- [ ] Backend config con bucket y region del cliente
- [ ] OIDC role ARN configurado en workflows
- [ ] Módulos referenciados con version tag (no branch)
- [ ] tfvars por entorno con valores del cliente
- [ ] .gitignore incluye: .terraform/, *.tfstate, *.tfplan
- [ ] README con instrucciones de setup inicial
- [ ] Sin credenciales del cliente en el scaffold

## Nota

Este skill es para Fase 5. No generar scaffolds completos antes de tener módulos publicados en registry. En Fases 1-4, el onboarding de cliente se hace copiando el blueprint directamente.
