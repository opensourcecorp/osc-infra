locals {
  keypair_name_tag = var.keypair_name != "" ? var.keypair_name : "N/A"
  sg_ids           = [data.aws_security_group.common.id, aws_security_group.main.id]
  subnet_id        = data.aws_subnets.main.ids[0] # TODO: Grab the first one for now, we'll try to be more robust out later

  default_tags = {
    "osc:core"        = var.is_osc_core ? "true" : "false"
    module_source     = "https://github.com/opensourcecorp/osc-infra//infracode/providers/aws/ec2_instance"
    deployment_source = var.source_address
  }
}

variable "app_name" {
  description = "Friendly name of application/platform being built"
  type        = string
}

variable "configmgmt_address" {
  description = "IP or DNS name of configmgmt"
  type        = string
  default     = "configmgmt.service.consul"
}

variable "desired_private_ip" {
  description = "Desired private IP to associate to the instance. Must also specify use_static_ip = true"
  type        = string
  default     = ""
}

variable "instance_profile_name" {
  description = "Name of the IAM Instance Profile to attach to the instance"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "AWS EC2 instance type"
  type        = string
}

variable "is_osc_core" {
  description = "Whether the deployment represent core OSC infrastructure. Defaults to 'false' to prevent accidental misrepresenation"
  type        = bool
  default     = false
}

variable "keypair_name" {
  description = "Name of SSH Keypair used to connect to the instance"
  type        = string
  default     = ""
}

variable "name_tag" {
  description = "Value for 'Name' tags"
  type        = string
}

variable "sg_rules_maplist" {
  description = "List-Map of custom Security Group Rules for the application/platform"
  type        = list(any)
  default     = []
}

variable "source_address" {
  description = "URI to the source of the code that actually calls this module"
  type        = string
}

variable "source_ami_filter" {
  description = "String pattern used in filtering the source AMI name"
  type        = string
  default     = "*imgbuilder*"
}

variable "subnet_cidr_filter" {
  description = "Optional CIDR block filter for finding a subnet to launch the instance into. This helps ensure your desired_private_ip will successfully attach"
  type        = string
  default     = ""
}

variable "subnet_name_filter" {
  description = "Name Tag filter for finding a subnet to launch the instance into"
  type        = string
  default     = "osc_public"
}

variable "use_static_ip" {
  description = "Whether to assign a static IP (EIP) to the instance. When setting this to true, can also optionally specify desired_private_ip"
  type        = bool
  default     = false
}

variable "use_spot_instance" {
  description = "Whether or not to use EC2 Spot Instances"
  type        = bool
  default     = true
}

# variable "user_data_string" {
#   description = "Command(s) to be run at first boot. If more than a single command, consider passing the 'user_data_filepath' variable instead"
#   type        = string
#   default     = <<-EOF
#     #!/usr/bin/env bash
#     rm -rf /etc/salt/pki/
#     salt-call state.apply
#   EOF
# }

# variable "user_data_filepath" {
#   description = "Path to file containing a user data script to be run at first boot"
#   type        = string
#   default     = ""
# }

variable "volume_size" {
  description = "Size of root volume, in GiB"
  type        = number
  default     = 16
}

variable "vpc_name_filter" {
  description = "Name Tag filter for finding a VPC to launch the instance resources into"
  type        = string
  default     = "osc"
}
