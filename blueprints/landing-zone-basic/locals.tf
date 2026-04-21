locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    ManagedBy   = "opentofu"
    CostCenter  = var.cost_center
  }
  name_prefix = "${var.project}-${var.environment}"
}
