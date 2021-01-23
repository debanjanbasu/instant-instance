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

variable "ssm_ami_parameter_name" {
  default     = ""
  description = "The old ami id to cleanup"
  type        = string
}
