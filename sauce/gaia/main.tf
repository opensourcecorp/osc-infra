terraform {
  backend "s3" {}
}

variable "app_name" {}
variable "keypair_name" {}

module "ec2" {
  # source = "github.com/opensourcecorp/gaia//providers/aws/ec2_instance"
  source = "../../gaia/providers/aws/ec2_instance"

  app_name           = var.app_name
  instance_type      = "t3a.micro"
  is_osc_core        = true
  keypair_name       = var.keypair_name
  name_tag           = var.app_name
  source_address     = "https://github.com/opensourcecorp/${var.app_name}.git"
  source_ami_filter  = "*${var.app_name}*"
}
