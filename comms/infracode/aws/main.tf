terraform {
  backend "s3" {}
}

variable "app_name" {}
variable "port" {}
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
  source_uri         = "https://github.com/opensourcecorp/${var.app_name}.git"

  sg_rules_maplist = [
    {
      port        = var.port
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}
