terraform {
  backend "s3" {
    bucket  = "terraform-state-csdac-tspace"
    key     = "terraform/s3/terraform.tfstate"
    region  = "us-west-1"
    encrypt = true
  }
}
