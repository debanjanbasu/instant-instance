resource "aws_vpc" "instant_instance_vpc" {
  cidr_block                       = var.vpc_cidr_block
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true
  tags = merge(var.additional_tags, {
    Name = "${var.vpc_name}-vpc"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id                          = aws_vpc.instant_instance_vpc.id
  cidr_block                      = cidrsubnet(aws_vpc.instant_instance_vpc.cidr_block, 8, count.index)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.instant_instance_vpc.ipv6_cidr_block, 8, count.index)
  availability_zone               = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags = merge(var.additional_tags, {
    Name = "${var.vpc_name}-subnet-${data.aws_availability_zones.available.names[count.index]}"
    Tier = "public"
  })
}

resource "aws_internet_gateway" "public_subnet_igw" {
  vpc_id = aws_vpc.instant_instance_vpc.id
  tags = merge(var.additional_tags, {
    Name = "${var.vpc_name}-igw"
  })
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.instant_instance_vpc.id
  tags = merge(var.additional_tags, {
    Name = "${var.vpc_name}-rtb"
    Tier = "public"
  })
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public_subnet_igw.id
}

resource "aws_main_route_table_association" "main_rtb" {
  vpc_id         = aws_vpc.instant_instance_vpc.id
  route_table_id = aws_route_table.public.id
}

# VPC Endpoints for S3 Access
data "aws_vpc_endpoint_service" "s3" {
  service = "s3"
}
resource "aws_vpc_endpoint" "private_s3" {
  vpc_id       = aws_vpc.instant_instance_vpc.id
  service_name = data.aws_vpc_endpoint_service.s3.service_name

  tags = merge(var.additional_tags, {
    Name = "${var.vpc_name}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint_route_table_association" "s3_endpoint_assoc" {
  route_table_id  = aws_route_table.public.id
  vpc_endpoint_id = aws_vpc_endpoint.private_s3.id
}
