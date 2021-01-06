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
