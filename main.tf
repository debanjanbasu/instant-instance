locals {
  instance_name = "cloud-gaming"
}

# You cannot create a new backend by simply defining this and then
# immediately proceeding to "terraform apply". The S3 backend must
# be bootstrapped according to the simple yet essential procedure in
# https://github.com/cloudposse/terraform-aws-tfstate-backend#usage
module "terraform_state_backend" {
  source                        = "git::https://github.com/cloudposse/terraform-aws-tfstate-backend.git?ref=master"
  namespace                     = lookup(var.additional_tags, "Namespace", "instant-instance")
  stage                         = "build"
  name                          = "terraform-state-bucket"
  attributes                    = ["state"]
  enable_server_side_encryption = true
  enable_public_access_block    = true

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false
}

module "instant_instance_vpc" {
  source          = "./modules/vpc"
  additional_tags = var.additional_tags
  vpc_name        = "instant-instance"
}

data "aws_ssm_parameter" "backed_up_ami" {
  name       = "${local.instance_name}-latest-ami-id"
  depends_on = [module.instant_instance]
}

module "instant_instance" {
  source          = "./modules/cloud-gaming-instance"
  additional_tags = var.additional_tags
  vpc_id          = module.instant_instance_vpc.vpc_id
  instance_type   = "g4dn.2xlarge"
  instance_name   = local.instance_name
  # Check pricing from https://aws.amazon.com/ec2/spot/pricing/
  # TODO - Automate in the future
  spot_max_price = 1.0
  # IMP - Please install the tools and all in the first time
  skip_install = false
  # This ami id would keep on changing
  # custom_ami   = data.aws_ssm_parameter.backed_up_ami.value
  # custom_ami = ""
}
