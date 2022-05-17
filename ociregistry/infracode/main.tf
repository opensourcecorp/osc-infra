terraform {
  backend "s3" {}
}

variable "app_name" {}
variable "db_port" {}
variable "keypair_name" {}

module "ec2" {
  # source = "github.com/opensourcecorp/infracode//providers/aws/ec2_instance"
  source = "../../infracode/providers/aws/ec2_instance"

  app_name       = var.app_name
  instance_type  = "t3a.micro"
  is_osc_core    = true
  keypair_name   = var.keypair_name
  name_tag       = var.app_name
  source_address = "https://github.com/opensourcecorp/${var.app_name}.git"
  source_ami_filter  = "*${var.app_name}*"

  sg_rules_maplist = [
    {
      port        = var.db_port
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}
