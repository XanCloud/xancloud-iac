output "vpcs" {
  description = "Map of VPC information"
  value = {
    for vpc_key in keys(var.vpcs) : vpc_key => {
      id         = aws_vpc.this[vpc_key].id
      cidr_block = aws_vpc.this[vpc_key].cidr_block
    }
  }
}

output "vpc_id" {
  description = "Map of VPC IDs by VPC key"
  value       = { for vpc_key in keys(var.vpcs) : vpc_key => aws_vpc.this[vpc_key].id }
}

output "vpc_cidrs" {
  description = "Map of VPC CIDR blocks by VPC key"
  value       = { for vpc_key in keys(var.vpcs) : vpc_key => var.vpcs[vpc_key].cidr }
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs by VPC key and AZ index"
  value = {
    for key, subnet in aws_subnet.public : key => subnet.id
  }
}

output "private_subnet_ids" {
  description = "Map of private subnet IDs by VPC key and AZ index"
  value = {
    for key, subnet in aws_subnet.private : key => subnet.id
  }
}

output "public_subnet_ids_by_vpc" {
  description = "Map of lists of public subnet IDs grouped by VPC key"
  value = {
    for vpc_key in keys(var.vpcs) : vpc_key => [
      for i in range(var.vpcs[vpc_key].azs) : aws_subnet.public["${vpc_key}-${i}"].id
    ]
  }
}

output "private_subnet_ids_by_vpc" {
  description = "Map of lists of private subnet IDs grouped by VPC key"
  value = {
    for vpc_key in keys(var.vpcs) : vpc_key => [
      for i in range(var.vpcs[vpc_key].azs) : aws_subnet.private["${vpc_key}-${i}"].id
    ]
  }
}

output "nat_gateway_ids" {
  description = "Map of lists of NAT Gateway IDs by VPC key (ordered by AZ index)"
  value = {
    for vpc_key in keys(var.vpcs) : vpc_key => [
      for i in range(var.vpcs[vpc_key].single_nat ? 1 : var.vpcs[vpc_key].azs) : aws_nat_gateway.this["${vpc_key}-${i}"].id
    ]
  }
}

output "flow_logs_s3_bucket_arns" {
  description = "Map of S3 bucket ARNs for VPC flow logs by VPC key (empty if cloudwatch destination)"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => vpc.flow_logs_destination == "s3" ? aws_s3_bucket.flow_logs[vpc_key].arn : ""
  }
}

output "flow_logs_cloudwatch_log_group_arns" {
  description = "Map of CloudWatch Log Group ARNs for VPC flow logs by VPC key (empty if s3 destination)"
  value = {
    for vpc_key, vpc in var.vpcs : vpc_key => vpc.flow_logs_destination == "cloudwatch" ? aws_cloudwatch_log_group.flow_logs[vpc_key].arn : ""
  }
}
