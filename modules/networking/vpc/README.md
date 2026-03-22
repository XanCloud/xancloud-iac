# VPC Module

Creates VPCs with public/private subnets, NAT Gateways, VPC Endpoints, and Flow Logs.

Supports multiple VPCs via `for_each` - instantiate once with a map of VPC configurations.

## Architecture

```
Internet
    │
    └──► IGW ──► Public Subnets (1/AZ, /24)
                        │
                        └──► NAT GW (shared or 1/AZ) ──► Private Subnets (1/AZ, /24)
                                                              │
                                                              └──► VPC Endpoints (S3, DynamoDB, SSM, etc.)
```

## Features

- VPC with DNS support enabled
- Public subnets with auto-assign public IP
- Private subnets for application workloads
- NAT Gateways: shared (1) or distributed (1/AZ)
- Gateway Endpoints: S3, DynamoDB
- Interface Endpoints: SSM, ECR API/DKR, Logs, Secrets Manager, etc.
- VPC Flow Logs to CloudWatch or S3

## Usage

```hcl
module "vpc" {
  source = "../../modules/networking/vpc"

  environment = "prod"
  project     = "myapp"
  owner       = "platform-team"
  cost_center = "CC-001"

  vpcs = {
    main = {
      cidr                  = "10.2.0.0/16"
      azs                   = 3
      single_nat            = false
      vpc_endpoints         = ["s3", "ssm", "ecr.api", "logs"]
      flow_logs_destination = "cloudwatch"
    }
    data = {
      cidr                  = "10.3.0.0/16"
      azs                   = 2
      single_nat            = true
      vpc_endpoints         = ["s3", "dynamodb"]
      flow_logs_destination = "s3"
    }
  }
}
```

## Subnet Layout

For a `/16` VPC with 3 AZs:

| Subnet      | AZ1        | AZ2        | AZ3        |
|-------------|------------|------------|------------|
| Public /24  | 10.x.0.0/24 | 10.x.1.0/24 | 10.x.2.0/24 |
| Private /24 | 10.x.3.0/24 | 10.x.4.0/24 | 10.x.5.0/24 |

## NAT Gateway Logic

| single_nat | NAT Gateways | Private Route Tables |
|------------|--------------|---------------------|
| `true`     | 1 (AZ1)      | All point to same NAT GW |
| `false`    | 1 per AZ     | Each points to its AZ's NAT GW |

## VPC Endpoints

**Gateway Endpoints:**
- S3
- DynamoDB

**Interface Endpoints:**
- SSM, SSM Messages, SSM Contacts
- ECR API, ECR DKR
- Logs (CloudWatch Logs)
- Secrets Manager

## Flow Logs

| Destination | Resource Created |
|-------------|-----------------|
| `cloudwatch` | CloudWatch Log Group (90 day retention) + IAM Role + Flow Log |
| `s3`        | S3 Bucket (90 day lifecycle) + Flow Log |

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `environment` | `string` | — | Environment: `dev`, `staging`, `prod` |
| `project` | `string` | — | Project name (lowercase, 2-21 chars) |
| `owner` | `string` | `"platform-team"` | Resource owner |
| `cost_center` | `string` | `"CC-001"` | Cost center for billing |
| `extra_tags` | `map(string)` | `{}` | Additional tags |
| `vpcs` | `map(object)` | — | Map of VPC configurations |

### VPC Configuration Object

| Field | Type | Description |
|-------|------|-------------|
| `cidr` | `string` | VPC CIDR block (RFC 1918, /16 to /32) |
| `azs` | `number` | Number of AZs (2 or 3) |
| `single_nat` | `bool` | `true` = 1 shared NAT GW, `false` = 1 NAT GW per AZ |
| `vpc_endpoints` | `list(string)` | Endpoints to create: `s3`, `dynamodb`, `ssm`, `ecr.api`, `ecr.dkr`, `logs`, `secretsmanager` |
| `flow_logs_destination` | `string` | `cloudwatch` or `s3` |

## Outputs

| Name | Description |
|------|-------------|
| `vpcs` | Map of VPC info (id, cidr_block) by VPC key |
| `vpc_id` | Map of VPC IDs by VPC key |
| `vpc_cidrs` | Map of VPC CIDRs by VPC key |
| `public_subnet_ids` | Map of public subnet IDs |
| `private_subnet_ids` | Map of private subnet IDs |
| `public_subnet_ids_by_vpc` | Lists of public subnet IDs grouped by VPC |
| `private_subnet_ids_by_vpc` | Lists of private subnet IDs grouped by VPC |
| `nat_gateway_ids` | Map of NAT Gateway IDs by VPC key |
| `flow_logs_s3_bucket_arns` | S3 bucket ARNs for flow logs (empty if cloudwatch) |
| `flow_logs_cloudwatch_log_group_arns` | CloudWatch Log Group ARNs for flow logs |

## Requirements

- OpenTofu >= 1.11.0
- AWS Provider ~> 6.0
