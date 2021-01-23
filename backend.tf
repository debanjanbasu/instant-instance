terraform {
  required_version = ">= 0.12.2"

  backend "s3" {
    region         = "ap-southeast-2"
    bucket         = "instant-instance-build-terraform-state-state"
    key            = "terraform.tfstate"
    dynamodb_table = "instant-instance-build-terraform-state-state-lock"
    profile        = ""
    role_arn       = ""
    encrypt        = "true"
  }
}
