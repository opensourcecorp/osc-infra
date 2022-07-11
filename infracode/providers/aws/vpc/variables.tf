locals {
  default_tags = {
    "osc:core"        = var.is_osc_core ? "true" : "false"
    module_source     = "https://github.com/opensourcecorp/osc-infra//infracode/providers/aws/vpc"
    deployment_source = var.source_uri
  }

  n_subnets = length(data.aws_availability_zones.available.names)

  tags = merge(
    { Name = var.name_tag },
    local.default_tags
  )
}

variable "is_osc_core" {
  description = "Whether the deployment represent core OSC infrastructure. Defaults to 'false' to prevent accidental misrepresenation"
  type        = bool
  default     = false
}

variable "name_tag" {
  description = "Value for 'Name' tags"
  type        = string
  default     = "osc"
}

variable "source_uri" {
  description = "URI to the source of the code that actually calls this module"
  type        = string
}

variable "use_private_subnets" {
  description = "Whether to use private subnets. Private subnets will receive a NAT gateway, which costs extra, so this defaults to 'false'."
  type        = bool
  default     = false
}
