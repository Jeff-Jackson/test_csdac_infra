terraform {
  backend "s3" {
    bucket         = "terraform-state-cylon-tspace-<%= expansion(':REGION') %>-<%= expansion(':ENV') %>"
    key            = "<%= expansion(':REGION/:ENV/:BUILD_DIR/terraform.tfstate') %>"
    region         = "<%= expansion(':REGION') %>"
    encrypt        = true
    dynamodb_table = "terraform_csdac_cylon_locks"
  }
}
