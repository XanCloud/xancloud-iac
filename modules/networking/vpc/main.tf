data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# ─── Per-VPC resources ──────────────────────────────────────────────────────────

resource "aws_vpc" "this" {
  for_each = var.vpcs

  cidr_block           = each.value.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  for_each = var.vpcs

  vpc_id = aws_vpc.this[each.key].id

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-igw"
  })
}

# ─── Subnet CIDR calculation ───────────────────────────────────────────────────
# Each VPC gets 2 * azs subnets (public + private), each /24
# Public subnets: indices 0 to azs-1
# Private subnets: indices azs to 2*azs-1

locals {
  vpc_subnets = {
    for vpc_key, vpc in var.vpcs : vpc_key => {
      azs = slice(data.aws_availability_zones.available.names, 0, vpc.azs)
      public_cidrs = [
        for i in range(vpc.azs) :
        cidrsubnet(vpc.cidr, 8, i)
      ]
      private_cidrs = [
        for i in range(vpc.azs) :
        cidrsubnet(vpc.cidr, 8, vpc.azs + i)
      ]
    }
  }

  nat_gateway_keys = flatten([
    for vpc_key, vpc in var.vpcs : [
      for i in range(vpc.single_nat ? 1 : vpc.azs) : "${vpc_key}-${i}"
    ]
  ])
}

# ─── Public Subnets ────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  for_each = merge([
    for vpc_key, vpc in var.vpcs : {
      for i, az in local.vpc_subnets[vpc_key].azs : "${vpc_key}-${i}" => {
        vpc_key    = vpc_key
        az         = az
        cidr_block = local.vpc_subnets[vpc_key].public_cidrs[i]
      }
    }
  ]...)

  vpc_id                  = aws_vpc.this[each.value.vpc_key].id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.value.vpc_key}-public-${each.value.az}"
    Type = "public"
  })
}

# ─── Private Subnets ───────────────────────────────────────────────────────────

resource "aws_subnet" "private" {
  for_each = merge([
    for vpc_key, vpc in var.vpcs : {
      for i, az in local.vpc_subnets[vpc_key].azs : "${vpc_key}-${i}" => {
        vpc_key    = vpc_key
        az         = az
        cidr_block = local.vpc_subnets[vpc_key].private_cidrs[i]
      }
    }
  ]...)

  vpc_id                  = aws_vpc.this[each.value.vpc_key].id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.value.vpc_key}-private-${each.value.az}"
    Type = "private"
  })
}

# ─── Elastic IPs for NAT Gateways ─────────────────────────────────────────────

resource "aws_eip" "nat" {
  for_each = toset(local.nat_gateway_keys)

  domain = "vpc"

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-nat-eip"
  })

  depends_on = [aws_internet_gateway.this]
}

# ─── NAT Gateways ───────────────────────────────────────────────────────────────
# single_nat = true: 1 NAT GW in first AZ, shared by all private subnets
# single_nat = false: 1 NAT GW per AZ

resource "aws_nat_gateway" "this" {
  for_each = toset(local.nat_gateway_keys)

  allocation_id = aws_eip.nat[each.key].id

  subnet_id = aws_subnet.public[each.key].id

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-nat-gw"
  })

  depends_on = [aws_internet_gateway.this]
}

# ─── Route Tables ──────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  for_each = var.vpcs

  vpc_id = aws_vpc.this[each.key].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[each.key].id
  }

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-rtb-public"
    Type = "public"
  })
}

resource "aws_route_table" "private" {
  for_each = merge([
    for vpc_key, vpc in var.vpcs : {
      for i in range(vpc.azs) : "${vpc_key}-${i}" => {
        vpc_key    = vpc_key
        az_idx     = i
        single_nat = vpc.single_nat
      }
    }
  ]...)

  vpc_id = aws_vpc.this[each.value.vpc_key].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.value.single_nat ? "${each.value.vpc_key}-0" : "${each.value.vpc_key}-${each.value.az_idx}"].id
  }

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.value.vpc_key}-rtb-private-${each.value.az_idx}"
    Type = "private"
  })
}

# ─── Route Table Associations ──────────────────────────────────────────────────

resource "aws_route_table_association" "public" {
  for_each = merge([
    for vpc_key, vpc in var.vpcs : {
      for i in range(vpc.azs) : "${vpc_key}-${i}" => {
        vpc_key = vpc_key
      }
    }
  ]...)

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.value.vpc_key].id
}

resource "aws_route_table_association" "private" {
  for_each = merge([
    for vpc_key, vpc in var.vpcs : {
      for i in range(vpc.azs) : "${vpc_key}-${i}" => {
        vpc_key = vpc_key
      }
    }
  ]...)

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# ─── VPC Endpoints Security Group ─────────────────────────────────────────────

resource "aws_security_group" "vpc_endpoints" {
  for_each = var.vpcs

  name        = "${var.project}-${var.environment}-${each.key}-vpc-endpoints"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.this[each.key].id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [each.value.cidr]
    description = "HTTPS from VPC CIDR"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to internet"
  }

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-sg-vpc-endpoints"
  })
}

# ─── Gateway VPC Endpoints (S3, DynamoDB) ──────────────────────────────────────

resource "aws_vpc_endpoint" "s3" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if contains(vpc.vpc_endpoints, "s3")
  }

  vpc_id       = aws_vpc.this[each.key].id
  service_name = "com.amazonaws.${data.aws_region.current.id}.s3"

  route_table_ids = concat(
    [aws_route_table.public[each.key].id],
    [for rtb_key, rtb in aws_route_table.private : rtb.id
    if replace(rtb_key, "/^(.+)-[0-9]+$/", "$1") == each.key]
  )

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-vpce-s3"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if contains(vpc.vpc_endpoints, "dynamodb")
  }

  vpc_id       = aws_vpc.this[each.key].id
  service_name = "com.amazonaws.${data.aws_region.current.id}.dynamodb"

  route_table_ids = concat(
    [aws_route_table.public[each.key].id],
    [for rtb_key, rtb in aws_route_table.private : rtb.id
    if replace(rtb_key, "/^(.+)-[0-9]+$/", "$1") == each.key]
  )

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-vpce-dynamodb"
  })
}

# ─── Interface VPC Endpoints ───────────────────────────────────────────────────

locals {
  interface_endpoint_items = flatten([
    for vpc_key, vpc in var.vpcs : [
      for ep in vpc.vpc_endpoints : {
        vpc_key = vpc_key
        service = ep
      } if !contains(local.gateway_endpoints, ep)
    ]
  ])

  interface_endpoints_map = {
    for item in local.interface_endpoint_items : "${item.vpc_key}-${item.service}" => item
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints_map

  vpc_id            = aws_vpc.this[each.value.vpc_key].id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.${each.value.service}"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    for key, subnet in aws_subnet.private : subnet.id
    if replace(key, "/^(.+)-[0-9]+$/", "$1") == each.value.vpc_key
  ]

  security_group_ids = [aws_security_group.vpc_endpoints[each.value.vpc_key].id]

  private_dns_enabled = true

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.value.vpc_key}-vpce-${each.value.service}"
  })
}

# ─── VPC Flow Logs ─────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "flow_logs_assume_role" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if vpc.flow_logs_destination == "cloudwatch"
  }

  statement {
    sid     = "AllowFlowLogsAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_logs_permissions" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if vpc.flow_logs_destination == "cloudwatch"
  }

  statement {
    sid    = "AllowFlowLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      aws_cloudwatch_log_group.flow_logs[each.key].arn,
      "${aws_cloudwatch_log_group.flow_logs[each.key].arn}:*"
    ]
  }
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if vpc.flow_logs_destination == "cloudwatch"
  }

  name              = "/aws/vpc/${var.project}-${var.environment}-${each.key}"
  retention_in_days = 90

  # TODO(phase-2): Add KMS encryption with dedicated key.
  # Omitted in MVP to avoid KMS key proliferation. Flow logs are
  # low-sensitivity operational data. CloudTrail captures access.

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-flow-logs"
  })
}

resource "aws_iam_role" "flow_logs" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if vpc.flow_logs_destination == "cloudwatch"
  }

  name = "${var.project}-${var.environment}-${each.key}-flow-logs-role"

  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role[each.key].json

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-flow-logs-role"
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if vpc.flow_logs_destination == "cloudwatch"
  }

  name = "${var.project}-${var.environment}-${each.key}-flow-logs-policy"
  role = aws_iam_role.flow_logs[each.key].id

  policy = data.aws_iam_policy_document.flow_logs_permissions[each.key].json
}

resource "aws_flow_log" "cloudwatch" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if vpc.flow_logs_destination == "cloudwatch"
  }

  log_destination      = aws_cloudwatch_log_group.flow_logs[each.key].arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this[each.key].id
  iam_role_arn         = aws_iam_role.flow_logs[each.key].arn

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-flow-logs"
  })
}

resource "aws_s3_bucket" "flow_logs" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if vpc.flow_logs_destination == "s3"
  }

  bucket = "${var.project}-${var.environment}-${each.key}-flow-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-flow-logs"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if vpc.flow_logs_destination == "s3"
  }

  bucket = aws_s3_bucket.flow_logs[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if vpc.flow_logs_destination == "s3"
  }

  bucket                  = aws_s3_bucket.flow_logs[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if vpc.flow_logs_destination == "s3"
  }

  bucket = aws_s3_bucket.flow_logs[each.key].id

  rule {
    id     = "flow-logs-expiration"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

resource "aws_flow_log" "s3" {
  for_each = {
    for vpc_key, vpc in var.vpcs :
    vpc_key => vpc if vpc.flow_logs_destination == "s3"
  }

  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this[each.key].id
  log_destination      = aws_s3_bucket.flow_logs[each.key].arn

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${var.project}-${var.environment}-${each.key}-flow-logs"
  })
}
