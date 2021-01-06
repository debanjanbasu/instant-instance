variable "additional_tags" {
  default     = {}
  description = "Additional resource tags"
  type        = map(string)
}

variable "vpc_name" {
  default     = "instant-instance"
  description = "The name of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  default     = "10.0.0.0/16"
  description = "The CIDR block of the VPC"
  type        = string
}
