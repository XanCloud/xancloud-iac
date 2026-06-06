bucket       = "xancloud-dev-tfstate-<account-id>"
key          = "landing-zone-basic/prod/terraform.tfstate"
region       = "<region>"
encrypt      = true
kms_key_id   = "arn:aws:kms:<region>:<account-id>:key/<kms-key-id>"
use_lockfile = true
