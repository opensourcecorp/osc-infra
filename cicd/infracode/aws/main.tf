terraform {
  backend "s3" {}
}

variable "app_name" {}
variable "keypair_name" {}
variable "keypair_local_file" {}


# Controller node(s)
module "controller" {
  # source = "github.com/opensourcecorp/osc-infra//infracode/providers/aws/ec2_instance"
  source = "../../../infracode/providers/aws/ec2_instance"

  app_name           = var.app_name
  instance_type      = "t3a.micro"
  is_osc_core        = true
  keypair_local_file = var.keypair_local_file
  keypair_name       = var.keypair_name
  name_tag           = "${var.app_name}-controller"
  # TODO: this is no longer accurate, so fix it for everything
  source_address = "https://github.com/opensourcecorp/${var.app_name}.git"

  sg_rules_maplist = [
    {
      port        = 8080
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16", module.controller.my_ip]
    },
    {
      port        = 2222
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}

# # Agent node(s)
# module "agent" {
#   # source = "github.com/opensourcecorp/osc-infra//infracode/providers/aws/ec2_instance"
#   source = "../../../infracode/providers/aws/ec2_instance"

#   app_name          = var.app_name
#   instance_type     = "t3a.micro"
#   is_osc_core       = true
#   keypair_name      = var.keypair_name
#   name_tag          = "${var.app_name}-worker"
#   source_address    = "https://github.com/opensourcecorp/${var.app_name}.git"

#   # subnet_name_filter = "osc-private"
# }
