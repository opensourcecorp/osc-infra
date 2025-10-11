terraform {
  backend "s3" {
    key          = "opensourcecorp/osc-infra/infracode/terraform/networking.tfstate"
    use_lockfile = true
  }
}

provider "aws" {}
