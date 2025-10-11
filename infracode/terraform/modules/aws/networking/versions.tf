terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    http = {
      source = "hashicorp/http"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      "osc:core"        = var.is_osc_core ? "true" : "false"
      module_source     = "https://github.com/opensourcecorp/osc-infra//infracode/terraform/modules/aws/networking"
      deployment_source = var.source_uri
    }
  }
}
