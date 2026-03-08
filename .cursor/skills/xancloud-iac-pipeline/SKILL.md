---
name: xancloud-iac-pipeline
description: >
  Genera y revisa workflows de GitHub Actions para el proyecto xancloud-iac usando OpenTofu (NO Terraform).
  Trigger cuando se trabaje en .github/workflows/, se mencione CI/CD, deploy, plan, apply, drift detection,
  GitHub Actions, pipeline, workflow, OIDC, Checkov gate, approval flow, o cualquier automatización
  del ciclo de vida de infraestructura. También trigger cuando se mencione "tofu plan", "tofu apply",
  "tofu test" en contexto de automatización, o se pida configurar quality gates, environments de GitHub,
  o integración con Checkov/OPA en pipelines. Trigger incluso si el usuario dice "terraform" en contexto
  de CI/CD — el proyecto usa OpenTofu y este skill aplica los comandos correctos automáticamente.
---

# XanCloud IaC — Pipeline Generator

## Contexto

- **Tool:** OpenTofu >= 1.11. Binario: `tofu`. Nunca `terraform` en comandos de pipeline.
- **CI/CD:** GitHub Actions. Runner: `ubuntu-latest`.
- **Auth:** OIDC exclusivo (GitHub → IAM Role). Nunca secrets estáticos de AWS.
- **Policy:** Checkov como quality gate bloqueante en PRs.
- **Apply en prod:** Requiere aprobación manual via GitHub Environments.

## Workflows de Fase 1

| Workflow | Archivo | Trigger | Acción |
|---|---|---|---|
| Module Test | `module-test.yml` | PR a main (modules/**) | tofu fmt, validate, Checkov, tofu test |
| Blueprint Validate | `blueprint-validate.yml` | PR a main (blueprints/**) | tofu init, plan (mock vars), policy check |
| Deploy | `deploy.yml` | Push a main + env label | plan → approval manual → apply |
| Drift Detect | `drift-detect.yml` | Cron (diario) | plan en cada entorno, notifica si hay drift |
| Docs Gen | `docs-gen.yml` | PR a main | terraform-docs auto-commit |

## Patrones obligatorios

### OIDC Authentication

```yaml
permissions:
  id-token: write
  contents: read

- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: ${{ vars.AWS_REGION }}
    role-session-name: gha-${{ github.run_id }}
```

Nunca usar `aws-access-key-id` / `aws-secret-access-key`. Si el usuario los propone, señalar que el proyecto usa OIDC y redirigir.

### OpenTofu Setup

```yaml
- name: Setup OpenTofu
  uses: opentofu/setup-opentofu@v1
  with:
    tofu_version: "1.11.5"
```

No usar `hashicorp/setup-terraform`. El action es `opentofu/setup-opentofu`.

### Checkov Gate

```yaml
- name: Run Checkov
  uses: bridgecrewio/checkov-action@v12
  with:
    directory: .
    framework: terraform
    output_format: cli,sarif
    output_file_path: console,checkov.sarif
    soft_fail: false
    skip_check: ""  # No skip por defecto
```

`soft_fail: false` = bloqueante. No cambiar a `true` sin justificación documentada.

### Cambio de directorio por módulo

Para workflows que operan sobre módulos modificados, detectar cuáles cambiaron:

```yaml
- name: Get changed modules
  id: changes
  uses: dorny/paths-filter@v3
  with:
    filters: |
      modules:
        - 'modules/**'

- name: Identify modified modules
  if: steps.changes.outputs.modules == 'true'
  id: modules
  run: |
    MODULES=$(git diff --name-only ${{ github.event.before }} ${{ github.sha }} | grep '^modules/' | cut -d'/' -f1-3 | sort -u)
    echo "modules=$MODULES" >> $GITHUB_OUTPUT
```

### Approval en prod

```yaml
deploy-prod:
  environment: production
  needs: [plan-prod]
  # GitHub Environment "production" requiere approval manual configurado en repo settings
```

### tofu test en CI

```yaml
- name: Run tests
  working-directory: ${{ matrix.module }}
  run: |
    tofu init -input=false
    tofu test
```

## Convenciones de workflows

### Naming de archivos
- Snake-case: `module-test.yml`, `drift-detect.yml`.
- Prefijo por función: module-*, blueprint-*, deploy-*, drift-*.

### Secrets y variables
- **Secrets:** `AWS_ROLE_ARN` (por environment).
- **Variables:** `AWS_REGION`, `TOFU_VERSION`.
- Nunca secrets de AWS credentials (access key / secret key).

### Concurrency

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # Para PRs. false para deploy.
```

### Caching

```yaml
- name: Cache OpenTofu plugins
  uses: actions/cache@v4
  with:
    path: ~/.terraform.d/plugin-cache
    key: ${{ runner.os }}-tofu-${{ hashFiles('**/.terraform.lock.hcl') }}
    restore-keys: |
      ${{ runner.os }}-tofu-
```

## Checklist antes de entregar un workflow

- [ ] Usa `tofu` en todos los comandos (nunca `terraform`)
- [ ] Auth con OIDC (`aws-actions/configure-aws-credentials` + `role-to-assume`)
- [ ] Sin secrets estáticos de AWS
- [ ] `opentofu/setup-opentofu` (no `hashicorp/setup-terraform`)
- [ ] Checkov como quality gate con `soft_fail: false`
- [ ] Concurrency group configurado
- [ ] Permissions mínimos declarados
- [ ] Apply en prod con environment + approval
- [ ] Cache de plugins configurado

## Qué NO generar

- Workflows para Azure DevOps (el proyecto usa GitHub Actions; migración a AzDO se documenta pero no se implementa en Fase 1).
- Steps con `terraform` como binario.
- Auth con access keys estáticos.
- Workflows que hagan apply sin plan previo.
