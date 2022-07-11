terraform {
  backend "s3" {}
}

provider "aws" {}

module "aws_vpc" {
  source = "../../providers/aws/vpc"

  is_osc_core    = true
  source_uri = "https://github.com/opensourcecorp/infracode.git"
}
