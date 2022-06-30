terraform {
  backend "s3" {}
}

variable "app_name" {}
variable "keypair_name" {}
variable "keypair_local_file" {}

module "ec2" {
  # source = "github.com/opensourcecorp/osc-infra//infracode/providers/aws/ec2_instance"
  source = "../../../infracode/providers/aws/ec2_instance"

  app_name           = var.app_name
  instance_type      = "t3a.micro"
  is_osc_core        = true
  keypair_local_file = var.keypair_local_file
  keypair_name       = var.keypair_name
  name_tag           = var.app_name
  source_address     = "https://github.com/opensourcecorp/${var.app_name}.git"

  desired_private_ip = "10.0.1.11"
  subnet_cidr_filter = "10.0.1.0/24"
  use_static_ip      = true

  sg_rules_maplist = [
    {
      port        = 8300
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      port        = 8301
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      port        = 8301
      protocol    = "udp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      port        = 8302
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      port        = 8302
      protocol    = "udp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      port        = 8500
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      port        = 8501
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      port        = 8502
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      port        = 8600
      protocol    = "udp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}
