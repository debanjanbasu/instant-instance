terraform {
  required_version = ">= 0.12.2"

  backend "s3" {
    region         = "ap-southeast-2"
    bucket         = "instant-instance-test-terraform-state-bucket-state"
    key            = "terraform.tfstate"
    dynamodb_table = "instant-instance-test-terraform-state-bucket-state-lock"
    profile        = ""
    role_arn       = ""
    encrypt        = "true"
  }
}
