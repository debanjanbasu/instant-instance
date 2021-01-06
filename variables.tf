variable "aws_region" {
  default     = "ap-southeast-2"
  description = "The region wherein the infra would be deployed"
  type        = string
}
variable "profile" {
  description = "The AWS profile to use for deployment"
  type        = string
  default     = "default"
}

variable "additional_tags" {
  default = {
    Namespace = "instant-instance"
  }
  description = "Additional resource tags"
  type        = map(string)
}
