provider "aws" {
  region  = var.region
}

variable "region" {
  type = string
  default = "us-west-1"
}

data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket" "cosign-storage" {
  bucket = "csdac-cosign"

  tags = {
    Name        = "CSDAC cosign"
    Environment = "Dev"
    DataClassification = "Cisco Public"
    IntendedPublic = "True"
  }
}

resource "aws_s3_bucket_acl" "cosign-storage-acl" {
  bucket = aws_s3_bucket.cosign-storage.id
  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "WRITE"
    }

    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/global/AllUsers"
      }
      permission = "READ"
    }

    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning_cosign" {
  bucket = aws_s3_bucket.cosign-storage.id
  versioning_configuration {
    status = "Enabled"
  }
}
output "bucket_arn" {
  value = aws_s3_bucket.cosign-storage.arn
}
