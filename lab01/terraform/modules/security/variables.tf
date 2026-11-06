variable "vpc_id" {
  type = string
}

variable "ssh_cidr" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.ssh_cidr)) && endswith(var.ssh_cidr, "/32")
    error_message = "ssh_cidr must be a valid IPv4 /32."
  }
}
