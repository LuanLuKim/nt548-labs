mock_provider "aws" {
  override_during = plan
}

variables {
  project           = "nt548-test"
  ami_id            = "ami-00000000000000000"
  instance_type     = "t3.micro"
  key_name          = "test-only"
  public_subnet_id  = "subnet-00000000000000001"
  private_subnet_id = "subnet-00000000000000002"
  public_sg_id      = "sg-00000000000000001"
  private_sg_id     = "sg-00000000000000002"
}

run "instance_policy" {
  command = apply
  assert {
    condition = (
      aws_instance.public.associate_public_ip_address &&
      !aws_instance.private.associate_public_ip_address &&
      aws_instance.public.subnet_id == var.public_subnet_id &&
      aws_instance.private.subnet_id == var.private_subnet_id &&
      aws_instance.public.vpc_security_group_ids == toset([var.public_sg_id]) &&
      aws_instance.private.vpc_security_group_ids == toset([var.private_sg_id])
    )
    error_message = "EC2 public-IP, subnet or SG assignment is wrong."
  }
  assert {
    condition = alltrue([
      for instance in [aws_instance.public, aws_instance.private] :
      instance.ami == var.ami_id && instance.instance_type == var.instance_type &&
      instance.key_name == var.key_name &&
      instance.metadata_options[0].http_tokens == "required" &&
      instance.root_block_device[0].encrypted &&
      instance.root_block_device[0].delete_on_termination &&
      instance.root_block_device[0].volume_type == "gp3"
    ])
    error_message = "AMI, type, key, IMDSv2 or encrypted EBS policy is wrong."
  }
}
