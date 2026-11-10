terraform {
  backend "s3" {
    bucket       = "nt548-tfstate-wtf12"
    key          = "lab01/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
