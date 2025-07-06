variable "stage" {
  description = "Stage of deployment: Dev or Prod"
  type        = string
  default     = "Dev"
}

variable "region" {
description = "AWS Region"
type = string
}

variable "ami" {
description = "AMI ID"
type = string
}

variable "instance_type" {
description = "EC2 Instance Type"
type = string
}

variable "shutdown_delay_minutes" {
description = "Minutes after which the EC2 instance shuts down automatically"
type = number
default = 15
}
