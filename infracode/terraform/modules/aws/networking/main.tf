module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  azs                = data.aws_availability_zones.available.names
  cidr               = local.vpc_cidr
  enable_nat_gateway = false
  name               = var.name
  private_subnets    = [for i in range(0, local.az_count) : cidrsubnet(local.vpc_cidr, 8, i + 1)]                  # will be e.g. 10.0.[1-3].0/24
  public_subnets     = [for i in range(0, local.az_count) : cidrsubnet(local.vpc_cidr, 8, i + 1 + local.az_count)] # will be e.g. 10.0.[4-6].0/24
}
