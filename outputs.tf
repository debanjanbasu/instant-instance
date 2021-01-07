output "s3_bucket_id" {
  value       = module.terraform_state_backend.s3_bucket_id
  description = "S3 bucket ID"
}

output "dynamodb_table_name" {
  value       = module.terraform_state_backend.dynamodb_table_name
  description = "DynamoDB table name"
}

output "dynamodb_table_id" {
  value       = module.terraform_state_backend.dynamodb_table_id
  description = "DynamoDB table ID"
}

output "vpc_id" {
  value       = module.instant_instance_vpc.vpc_id
  description = "The VPC id"
}
