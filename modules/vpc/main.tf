resource "aws_vpc" "instant_instance_vpc" {
  cidr_block                       = "10.0.0.0/16"
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true
  tags = merge(var.additional_tags, {
    Name = "${var.vpc_name}-vpc"
  })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.instant_instance_vpc.id
  service_name = "com.amazonaws.ap-southeast-2.s3"

  tags = merge(var.additional_tags, {
    Name = "${var.vpc_name}-s3-endpoint"
  })
}
