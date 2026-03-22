locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    ManagedBy   = "opentofu"
    CostCenter  = var.cost_center
  }

  gateway_endpoints = ["s3", "dynamodb"]
}
