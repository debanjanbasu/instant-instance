output "instance_id" {
  value = aws_spot_instance_request.windows_instance.spot_instance_id
}

output "instance_ip" {
  value = aws_spot_instance_request.windows_instance.public_ip
}

output "instance_public_dns" {
  value = aws_spot_instance_request.windows_instance.public_dns
}

output "cloud_gaming_latest_ami_id" {
  value = aws_ssm_parameter.cloud_gaming_latest_ami_id.value
}

output "instance_password" {
  value     = random_password.password.result
  sensitive = true
}
