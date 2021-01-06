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
  source             = "./modules/vpc"
  additional_tags    = var.additional_tags
  vpc_name           = "instant_instance"
}
