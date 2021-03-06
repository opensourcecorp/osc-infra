terraform {
  backend "s3" {}
}

variable "app_name" {}
variable "keypair_name" {}

module "ec2" {
  # source = "github.com/opensourcecorp/osc-infra//infracode/providers/aws/ec2_instance"
  source = "../../osc-infra/infracode/providers/aws/ec2_instance"

  app_name          = var.app_name
  instance_type     = "t3a.micro"
  is_osc_core       = true
  keypair_name      = var.keypair_name
  name_tag          = var.app_name
  source_address    = "https://github.com/opensourcecorp/${var.app_name}.git"
  source_ami_filter = "*${var.app_name}*"
  # user_data_filepath = "../scripts/install.sh"

  desired_private_ip = "10.0.1.10"
  subnet_cidr_filter = "10.0.1.0/24"
  use_static_ip      = true

  sg_rules_maplist = [
    {
      port        = 4505
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      port        = 4506
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}
