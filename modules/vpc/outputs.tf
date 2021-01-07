output "vpc_id" {
  value       = aws_vpc.instant_instance_vpc.id
  description = "The VPC id"
}
