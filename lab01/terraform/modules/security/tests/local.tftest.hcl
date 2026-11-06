mock_provider "aws" {
  override_during = plan
}

variables {
  vpc_id   = "vpc-00000000000000001"
  ssh_cidr = "203.0.113.10/32"
}

run "ssh_policy" {
  command = apply
  assert {
    condition = (
      aws_security_group.public.vpc_id == var.vpc_id &&
      aws_security_group.private.vpc_id == var.vpc_id &&
      aws_vpc_security_group_ingress_rule.public_ssh.security_group_id == aws_security_group.public.id &&
      aws_vpc_security_group_ingress_rule.public_ssh.cidr_ipv4 == var.ssh_cidr &&
      aws_vpc_security_group_ingress_rule.public_ssh.ip_protocol == "tcp" &&
      aws_vpc_security_group_ingress_rule.public_ssh.from_port == 22 &&
      aws_vpc_security_group_ingress_rule.public_ssh.to_port == 22
    )
    error_message = "Public SSH must be TCP 22 from the selected /32."
  }
  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.private_ssh.security_group_id == aws_security_group.private.id &&
      aws_vpc_security_group_ingress_rule.private_ssh.referenced_security_group_id == aws_security_group.public.id &&
      aws_vpc_security_group_ingress_rule.private_ssh.cidr_ipv4 == null &&
      aws_vpc_security_group_ingress_rule.private_ssh.ip_protocol == "tcp" &&
      aws_vpc_security_group_ingress_rule.private_ssh.from_port == 22 &&
      aws_vpc_security_group_ingress_rule.private_ssh.to_port == 22
    )
    error_message = "Private SSH must reference the public SG on TCP 22."
  }
  assert {
    condition = (
      aws_vpc_security_group_egress_rule.public_all.security_group_id == aws_security_group.public.id &&
      aws_vpc_security_group_egress_rule.private_all.security_group_id == aws_security_group.private.id &&
      aws_vpc_security_group_egress_rule.public_all.cidr_ipv4 == "0.0.0.0/0" &&
      aws_vpc_security_group_egress_rule.private_all.cidr_ipv4 == "0.0.0.0/0" &&
      aws_vpc_security_group_egress_rule.public_all.ip_protocol == "-1" &&
      aws_vpc_security_group_egress_rule.private_all.ip_protocol == "-1"
    )
    error_message = "Outbound rules do not match this lab's selected policy."
  }
}

run "reject_open_ssh" {
  command = plan
  variables {
    ssh_cidr = "0.0.0.0/0"
  }
  expect_failures = [var.ssh_cidr]
}
