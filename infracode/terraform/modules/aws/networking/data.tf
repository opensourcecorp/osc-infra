locals {
  az_count = length(data.aws_availability_zones.available.names)
  vpc_cidr = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {}

data "aws_region" "current" {}
