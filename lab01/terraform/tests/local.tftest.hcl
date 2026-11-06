mock_provider "aws" {
  override_during = plan
}

variables {
  ssh_cidr = "203.0.113.10/32"
  ami_id   = "ami-00000000000000000"
  key_name = "test-only"
}

run "root_wiring" {
  command = apply
  assert {
    condition = (
      output.vpc_id == module.network.vpc_id &&
      output.network.public_subnet_id == module.network.public_subnet_id &&
      output.network.private_subnet_id == module.network.private_subnet_id &&
      output.network.nat_id == module.network.nat_id &&
      output.security.public_sg_id == module.security.public_sg_id &&
      output.security.private_sg_id == module.security.private_sg_id &&
      output.instances.public_instance_id == module.compute.public_instance_id &&
      output.instances.private_instance_id == module.compute.private_instance_id
    )
    error_message = "Root outputs are not wired to their intended module outputs."
  }
}
