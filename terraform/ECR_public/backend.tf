terraform {
  backend "s3" {
    bucket  = "terraform-state-csdac-tspace"
    key     = "terraform/ECR_public/terraform.tfstate"
    region  = "us-west-1"
    encrypt = true
  }
}
