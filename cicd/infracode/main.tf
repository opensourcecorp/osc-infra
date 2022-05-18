terraform {
  backend "s3" {}
}

variable "app_name" {}
variable "keypair_name" {}

# Web node(s)
module "web" {
  # source = "github.com/opensourcecorp/infracode//providers/aws/ec2_instance"
  source = "../../infracode/providers/aws/ec2_instance"

  app_name          = var.app_name
  instance_type     = "t3a.micro"
  is_osc_core       = true
  keypair_name      = var.keypair_name
  name_tag          = "${var.app_name}-web"
  source_address    = "https://github.com/opensourcecorp/${var.app_name}.git"
  source_ami_filter = "*${var.app_name}-web*"

  sg_rules_maplist = [
    {
      port        = 8080
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16", "${chomp(data.http.my_ip.body)}/32"]
    },
    {
      port        = 2222
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}

# Worker node(s)
module "worker" {
  # source = "github.com/opensourcecorp/infracode//providers/aws/ec2_instance"
  source = "../../infracode/providers/aws/ec2_instance"

  app_name          = var.app_name
  instance_type     = "t3a.micro"
  is_osc_core       = true
  keypair_name      = var.keypair_name
  name_tag          = "${var.app_name}-worker"
  source_address    = "https://github.com/opensourcecorp/${var.app_name}.git"
  source_ami_filter = "*${var.app_name}-worker*"

  # subnet_name_filter = "osc-private"
}
