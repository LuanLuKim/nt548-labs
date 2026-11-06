variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
}

variable "public_cidr" {
  description = "IPv4 CIDR block for the public subnet."
  type        = string
}

variable "private_cidr" {
  description = "IPv4 CIDR block for the private subnet."
  type        = string
}

variable "az" {
  description = "Availability Zone for both subnets."
  type        = string
}