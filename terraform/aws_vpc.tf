
module "testmon_vpc" {
  source                = "terraform-aws-modules/vpc/aws"

  name                  = "testmon-vpc"
  cidr                  = "10.0.0.0/16"

  azs                   = ["us-east-1a", "us-east-1d"]
  private_subnets       = ["10.0.3.0/24", "10.0.4.0/24"]
  public_subnets        = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway    = true
  enable_vpn_gateway    = false
  single_nat_gateway    = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "testmon_ecs_sg" {
  source                                = "terraform-aws-modules/security-group/aws"
  name                                  = "testmon_ecs_sg"
  description                           = "Security group for testmon ecs."
  vpc_id                                = module.testmon_vpc.vpc_id
  # Required for tasks to pull images from ECR
  egress_cidr_blocks                    = ["0.0.0.0/0"]
  egress_rules                          = ["https-443-tcp"]
  # Required for traffic from clients
  ingress_cidr_blocks                   = ["10.0.0.0/8"]
  ingress_rules                         = ["http-80-tcp"]
}
