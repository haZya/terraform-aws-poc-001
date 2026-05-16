terraform {
  backend "s3" {
    bucket       = "poc-001-terraform-state-000000000000"
    key          = "poc-001/prod/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
