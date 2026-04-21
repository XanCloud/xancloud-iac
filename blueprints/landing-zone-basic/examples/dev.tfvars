region      = "us-east-1"
environment = "dev"
project     = "xancloud"

# This env owns account-level singletons in Phase 1
is_account_owner = true
account_alias    = "xancloud-dev"

vpcs = {
  main = {
    cidr                  = "10.10.0.0/16"
    azs                   = 2
    single_nat            = true
    vpc_endpoints         = ["s3", "ssm", "ssmmessages", "ecr.api", "ecr.dkr", "logs"]
    flow_logs_destination = "cloudwatch"
  }
}
