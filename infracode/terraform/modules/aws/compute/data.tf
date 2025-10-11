data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_ami" "latest" {
  most_recent = true
  owners      = [data.aws_caller_identity.current.account_id]

  filter {
    name   = "name"
    values = [var.source_ami_filter]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_security_group" "common" {
  filter {
    name   = "group-name"
    values = ["osc_common"]
  }

  vpc_id = data.aws_vpc.main.id
}

data "aws_subnets" "main" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_name_filter]
  }

  dynamic "filter" {
    for_each = var.subnet_cidr_filter != "" ? [var.subnet_cidr_filter] : []
    content {
      name   = "cidr-block"
      values = [var.subnet_cidr_filter]
    }
  }
}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name_filter]
  }
}

data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}
