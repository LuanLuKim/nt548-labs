output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "default_sg_id" {
  value = aws_vpc.this.default_security_group_id
}

output "nat_id" {
  value = aws_nat_gateway.nat.id
}

output "nat_eip" {
  value = aws_eip.nat_eip.public_ip
}

output "public_route_table_id" {
  value = aws_route_table.public_rt.id
}

output "private_route_table_id" {
  value = aws_route_table.private_rt.id
}
