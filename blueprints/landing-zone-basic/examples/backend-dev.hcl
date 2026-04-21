bucket       = "xancloud-tfstate-<account-id>"
key          = "landing-zone/dev/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
kms_key_id   = "arn:aws:kms:us-east-1:<account-id>:key/<kms-key-id>"
use_lockfile = true
