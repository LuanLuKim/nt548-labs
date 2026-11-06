module "network" {
  source       = "./modules/network"
  vpc_cidr     = var.vpc_cidr
  public_cidr  = var.public_cidr
  private_cidr = var.private_cidr
  az           = var.az
}

module "security" {
  source   = "./modules/security"
  vpc_id   = module.network.vpc_id
  ssh_cidr = var.ssh_cidr
}

module "compute" {
  source            = "./modules/compute"
  project           = var.project
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  public_subnet_id  = module.network.public_subnet_id
  private_subnet_id = module.network.private_subnet_id
  public_sg_id      = module.security.public_sg_id
  private_sg_id     = module.security.private_sg_id

  depends_on = [module.network, module.security]
}
