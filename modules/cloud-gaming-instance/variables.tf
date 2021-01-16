variable "additional_tags" {
  default     = {}
  description = "Additional resource tags"
  type        = map(string)
}

variable "instance_name" {
  default     = "cloud-gaming"
  description = "The name of the EC2 Spot Instance"
  type        = string
}

variable "instance_type" {
  default     = "g4dn.2xlarge"
  description = "The instance type"
  type        = string
}

variable "root_block_device_size_gb" {
  default     = 512
  description = "The root EBS volume size"
  type        = number
}

variable "spot_max_price" {
  default     = 1.5
  description = "The maximum price you are ready to pay for the instance"
  type        = number
}

variable "custom_ami" {
  default     = ""
  description = "The custome ami id to use once an ami has been created"
  type        = string
}

variable "vpc_id" {
  default     = ""
  description = "The VPC to deploy the instance into"
  type        = string
}

variable "skip_install" {
  description = "Skip installation step on startup. Useful when using a custom AMI that is already setup"
  type        = bool
  default     = false
}

variable "post_install" {
  default = {
    install_parsec              = true
    install_auto_login          = true
    install_graphic_card_driver = true
    install_steam               = false
    install_gog_galaxy          = false
    install_uplay               = false
    install_origin              = false
    install_epic_games_launcher = false
  }
  description = "Post install list"
  type        = map(string)
}
