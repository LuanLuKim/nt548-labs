resource "aws_security_group" "public" {
  name_prefix = "nt548-public-"
  description = "SSH from the student IPv4 only"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "private" {
  name_prefix = "nt548-private-"
  description = "SSH from the public EC2 security group only"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "public_ssh" {
  description       = "SSH from the administrator IPv4 address"
  security_group_id = aws_security_group.public.id
  cidr_ipv4         = var.ssh_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "private_ssh" {
  description                  = "SSH from the public EC2 security group"
  security_group_id            = aws_security_group.private.id
  referenced_security_group_id = aws_security_group.public.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "public_all" {
  description       = "Outbound traffic from the public EC2 instance"
  security_group_id = aws_security_group.public.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "private_all" {
  description       = "Outbound traffic from the private EC2 instance through NAT"
  security_group_id = aws_security_group.private.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
