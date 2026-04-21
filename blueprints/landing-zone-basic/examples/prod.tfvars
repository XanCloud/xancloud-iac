region      = "us-east-1"
environment = "prod"
project     = "xancloud"

# dev owns the account in Phase 1
is_account_owner = false

vpcs = {
  main = {
    cidr                  = "10.20.0.0/16"
    azs                   = 3
    single_nat            = false
    vpc_endpoints         = ["s3", "ssm", "ssmmessages", "ecr.api", "ecr.dkr", "logs", "secretsmanager"]
    flow_logs_destination = "s3"
  }
}

cloudtrail_cloudwatch_logs_enabled = true
cloudtrail_log_retention_days      = 731
