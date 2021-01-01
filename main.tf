terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.22"
    }
  }

  backend "s3" {
    bucket         = "terraform-remote-state-storage-s3-instant-instance"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-dynamo-instant-instance"
    key            = "instant-instance/terraform.tfstate"
    region         = "ap-southeast-2"
  }
}

provider "aws" {
  profile = var.profile
  region  = "ap-southeast-2"
}

# terraform state file setup
# create an S3 bucket to store the state file in
resource "aws_s3_bucket" "terraform-state-storage-s3" {
  bucket = "terraform-remote-state-storage-s3-instant-instance"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags {
    Name = "S3 Remote Terraform State Store"
  }
}

# create a dynamodb table for locking the state file
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name           = "terraform-state-lock-dynamo-instant-instanc"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    Name = "DynamoDB Terraform State Lock Table"
  }
}

# Create a VPC
resource "aws_vpc" "custom-vpc" {
  cidr_block = "10.0.0.0/16"
}
