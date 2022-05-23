terraform {
  backend "s3" {}
}

provider "aws" {}

variable "custom_tags" {}

module "aws_vpc" {
  source = "../../providers/aws/vpc"

  custom_tags    = var.custom_tags
  is_osc_core    = true
  source_address = "https://github.com/opensourcecorp/infracode.git"
}
