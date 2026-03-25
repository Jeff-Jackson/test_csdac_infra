terraform {
  backend "s3" {
    bucket  = "terraform-state-csdac-tspace"
    #key     = "terraform/vault/terraform.tfstate"
    region  = "us-west-1"
    encrypt = true
  }
}
