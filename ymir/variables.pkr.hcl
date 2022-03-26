##########
# Locals #
##########
locals {
  boot_command    = var.boot_command
  disk_size       = 10240
  execute_command = "echo '${local.ssh_password}' | sudo -S bash -euo pipefail -c '{{ .Vars }} {{ .Path }}'"
  headless        = var.headless
  http_directory  = "http"
  # if you track 'current/' instead of 'archive/' for Debian, you'll need to update this file CONSTANTLY as the version changes, since they put non-latest images on a separate path
  iso_checksum        = "file:http://cdimage.debian.org/cdimage/archive/${var.os_version}/${var.arch}/iso-cd/SHA512SUMS"
  iso_url             = "http://cdimage.debian.org/cdimage/archive/${var.os_version}/${var.arch}/iso-cd/debian-${var.os_version}-${var.arch}-netinst.iso"
  shutdown_command    = "echo '${local.ssh_password}' | sudo -S shutdown -P now"
  ssh_password        = var.ssh_password
  ssh_port            = var.ssh_port
  ssh_username        = var.ssh_username
  ssh_wait_timeout    = "120m"
  virtualbox_ovf_path = "./output-virtualbox-iso-ymir/ymir-packer-${var.os_family}-${var.os_version}-${var.arch}.ovf"
  vm_name             = "${var.app_name}-packer-${var.os_family}-${var.os_version}-${var.arch}"

  # AWS
  source_ami_name_pattern = contains(["ymir"], var.app_name) ? "${var.os_family}-${var.os_version_major}-${var.arch}-*" : (var.source_ami_name_pattern == "" ? "*ymir*" : var.source_ami_name_pattern)
  source_ami_owner_id     = contains(["ymir"], var.app_name) ? "136693071363" : var.source_ami_owner_id
}

##################
# Shared/General #
##################
variable "app_name" {
  description = "Friendly name of application/platform being built"
  type        = string
}

variable "aether_address" {
  description = "Address of Aether master node/router"
  type        = string
  default     = "10.0.1.10"
}

variable "arch" {
  description = "System architecture slug to build on, e.g. 'amd64', 'aarch64', 'armv6', etc."
  type        = string
  default     = "amd64"
}

variable "boot_command" {
  description = "Boot command to apply at VM startup"
  type        = list(string)
  default = [
    "<esc><wait>",
    "install ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "debian-installer=en_US ",
    "auto ",
    "locale=en_US ",
    "kbd-chooser/method=us ",
    "keyboard-configuration/xkb-keymap=us ",
    "netcfg/get_hostname=debian ",
    "netcfg/get_domain=packer ",
    "netcfg/choose_interface=enp0s3 ", # in case of multiple network interfaces
    "fb=false ",
    "debconf/frontend=noninteractive ",
    "console-setup/ask_detect=false ",
    "console-keymaps-at/keymap=us ",
    "<enter>"
  ]
}

variable "build_delay" {
  description = "Seconds to delay before running build-time provisioner scripts. Useful for interactive debugging"
  type        = number
  default     = 0
}

variable "headless" {
  description = "Perform headless installation?"
  type        = bool
  default     = false
}

variable "my_ip" {
  description = "The IP address of the machine running Packer; used for setting firewall etc. rules"
  type        = string
  default     = "127.0.0.1"
}

variable "os_alias" {
  description = "OS version alias, e.g. 'bullseye' for Debian 11"
  type        = string
  default     = "bullseye"
}

variable "os_family" {
  description = "Family name of OS, e.g. 'debian'"
  type        = string
  default     = "debian"
}

variable "os_version" {
  description = "Full (semver) version number of OS, e.g. 1.0.0"
  type        = string
  default     = "11.0.0"
}

variable "os_version_major" {
  description = "Major semver number of OS; used for some interpolation"
  type        = string
  default     = "11"
}

variable "osc_root" {
  description = "The local root directory for your OpenSourceCorp repositories. Will default to your OSC_ROOT env var"
  type        = string
  default     = env("OSC_ROOT")

  validation {
    condition     = length(var.osc_root) > 0
    error_message = "Variable 'osc_root' could not be determined. You can set it with an environment variable called 'OSC_ROOT', or pass it into Packer explicitly."
  }
}

variable "shell_provisioner" {
  description = "Shell commands to run in the provisioning step"
  type        = list(string)
  default     = ["printf 'Skipping shell provisioner since none provided\n' > /dev/stderr"]
}

variable "source_files" {
  description = "Optional list of files/directories to copy into the builder as part of the file provisioner"
  type        = list(string)
  default     = ["./LICENSE"] # Needs a default so the provisioner doesn't fail
}

variable "ssh_password" {
  description = "SSH password"
  type        = string
  default     = "packer"
}
variable "ssh_port" {
  description = "SSH port"
  type        = number
  default     = 22
}
variable "ssh_username" {
  description = "SSH username"
  type        = string
  default     = "packer"
}

#######
# AWS #
#######
variable "source_ami_name_pattern" {
  description = "String pattern used in filtering the source AMI name. Heuristics used to determine if not enough info provided"
  type        = string
  default     = ""
}

variable "source_ami_owner_id" {
  description = "Owner ID of the source AMI; e.g. '136693071363' for Debian. Heuristics used to determine if not enough info provided"
  type        = string
  default     = ""
}

variable "ssh_interface" {
  description = "How Packer should connect to your EC2 instance. Options are 'public_ip', 'private_ip', 'public_dns', 'private_dns' or 'session_manager'."
  type        = string
  default     = "public_ip"
}

variable "subnet_name_tag" {
  description = "'Name' tag of build subnet, used to filter for Subnet ID"
  type        = string
  default     = "osc_public"
}

variable "vpc_name_tag" {
  description = "'Name' tag of build VPC, used to filter for VPC ID"
  type        = string
  default     = "osc"
}

variable "volume_size" {
  description = "Volume size, in GiB, of instances launched with this AMI"
  type        = number
  default     = 16
}

################
# DigitalOcean #
################
variable "do_api_token" {
  description = "DigitalOcean API Token"
  type        = string
  default     = "NOT_SET"
}

variable "do_droplet_size" {
  description = "Slug for Droplet size used to build the output image"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "do_region" {
  description = "DigitalOcean region slug"
  type        = string
  default     = "tor1"
}

variable "do_vpc_id" {
  description = "DigitalOcean VPC UUID"
  type        = string
  default     = "NOT_SET"
}

###########
# Proxmox #
###########
variable "proxmox_url" {
  description = "Full URL of the Proxmox cluster"
  type        = string
  default     = "NOT_SET"
}

variable "proxmox_iso_storage_pool" {
  description = "Name of the storage pool in Proxmox to store/retrieve the ISO file from"
  type        = string
  default     = "local"
}

variable "proxmox_stored_iso_file_name" {
  description = "Name of the ISO file stored on Proxmox"
  type        = string
  default     = "NOT_SET"
}

variable "proxmox_node" {
  description = "Name of Proxmox node to build on"
  type        = string
  default     = "pve"
}

variable "proxmox_skip_tls_verify" {
  description = "Skip TLS verification for Proxmox builder connection? Defaults to true"
  type        = bool
  default     = true
}

variable "proxmox_username" {
  description = "Login username for Proxmox user. See docs for required format"
  type        = string
  default     = "NOT_SET"
}

variable "proxmox_password" {
  description = "Login password for Proxmox user"
  type        = string
  default     = "NOT_SET"
}

##############
# VirtualBox #
##############
variable "virtualbox_memory" {
  description = "Amount of memory, in MiB, for the VBox builder VM"
  type        = number
  default     = 1024
}

variable "virtualbox_ovf_path" {
  description = "Path on disk to a VirtualBox OVF file"
  type        = string
  default     = ""
}
