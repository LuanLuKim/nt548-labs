mock_provider "aws" {
  override_during = plan
}

variables {
  vpc_cidr     = "10.10.0.0/16"
  public_cidr  = "10.10.1.0/24"
  private_cidr = "10.10.2.0/24"
  az           = "us-east-1a"
}

run "network_policy" {
  command = apply
  assert {
    condition = (
      aws_vpc.this.cidr_block == var.vpc_cidr &&
      aws_vpc.this.enable_dns_support && aws_vpc.this.enable_dns_hostnames &&
      aws_subnet.public_subnet.vpc_id == aws_vpc.this.id &&
      aws_subnet.private_subnet.vpc_id == aws_vpc.this.id &&
      aws_subnet.public_subnet.cidr_block == var.public_cidr &&
      aws_subnet.private_subnet.cidr_block == var.private_cidr &&
      aws_subnet.public_subnet.availability_zone == var.az &&
      aws_subnet.private_subnet.availability_zone == var.az &&
      !aws_subnet.private_subnet.map_public_ip_on_launch
    )
    error_message = "VPC, CIDRs, AZ or private subnet public-IP setting is wrong."
  }
  assert {
    condition = (
      aws_internet_gateway.igw.vpc_id == aws_vpc.this.id &&
      aws_route_table.public_rt.vpc_id == aws_vpc.this.id &&
      length(aws_route_table.public_rt.route) == 1 &&
      one(aws_route_table.public_rt.route).cidr_block == "0.0.0.0/0" &&
      one(aws_route_table.public_rt.route).gateway_id == aws_internet_gateway.igw.id &&
      aws_route_table_association.public_assoc.subnet_id == aws_subnet.public_subnet.id &&
      aws_route_table_association.public_assoc.route_table_id == aws_route_table.public_rt.id
    )
    error_message = "Public subnet must use its route table and IGW default route."
  }
  assert {
    condition = (
      aws_eip.nat_eip.domain == "vpc" &&
      aws_nat_gateway.nat.connectivity_type == "public" &&
      aws_nat_gateway.nat.subnet_id == aws_subnet.public_subnet.id &&
      aws_nat_gateway.nat.allocation_id == aws_eip.nat_eip.id &&
      aws_route_table.private_rt.vpc_id == aws_vpc.this.id &&
      length(aws_route_table.private_rt.route) == 1 &&
      one(aws_route_table.private_rt.route).cidr_block == "0.0.0.0/0" &&
      one(aws_route_table.private_rt.route).nat_gateway_id == aws_nat_gateway.nat.id &&
      aws_route_table_association.private_assoc.subnet_id == aws_subnet.private_subnet.id &&
      aws_route_table_association.private_assoc.route_table_id == aws_route_table.private_rt.id
    )
    error_message = "NAT, EIP, private default route or private association is wrong."
  }
  assert {
    condition     = output.default_sg_id == aws_vpc.this.default_security_group_id
    error_message = "Default SG output must refer to this VPC's default SG."
  }
}
