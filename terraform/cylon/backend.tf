terraform {
  backend "s3" {
        bucket   = "terraform-state-csdac-cylon"
        #key     = "terraform/cylon/terraform.tfstate"
        region   = "us-west-1"
    encrypt = true
  }
}
