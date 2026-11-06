output "vpc_id" {
  value = module.network.vpc_id
}

output "network" {
  value = {
    public_subnet_id       = module.network.public_subnet_id
    private_subnet_id      = module.network.private_subnet_id
    igw_id                 = module.network.igw_id
    nat_id                 = module.network.nat_id
    nat_eip                = module.network.nat_eip
    default_sg_id          = module.network.default_sg_id
    public_route_table_id  = module.network.public_route_table_id
    private_route_table_id = module.network.private_route_table_id
  }
}

output "security" {
  value = {
    public_sg_id  = module.security.public_sg_id
    private_sg_id = module.security.private_sg_id
  }
}

output "instances" {
  value = {
    public_instance_id  = module.compute.public_instance_id
    private_instance_id = module.compute.private_instance_id
    public_ip           = module.compute.public_ip
    public_private_ip   = module.compute.public_private_ip
    private_ip          = module.compute.private_ip
  }
}
