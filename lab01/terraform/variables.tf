variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "nt548-tf"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "public_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "private_cidr" {
  type    = string
  default = "10.10.2.0/24"
}

variable "az" {
  type    = string
  default = "us-east-1a"
}

variable "ssh_cidr" {
  description = "IPv4 /32 allowed to SSH to the public EC2."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.ssh_cidr)) && endswith(var.ssh_cidr, "/32")
    error_message = "ssh_cidr must be a valid IPv4 /32."
  }
}

variable "ami_id" {
  description = "Amazon Linux 2023 x86_64 AMI in the selected region."
  type        = string
}

variable "key_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}