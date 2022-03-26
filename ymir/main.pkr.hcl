packer {
  required_plugins {
    aws = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 0.0.1"
    }
    digitalocean = {
      source  = "github.com/hashicorp/digitalocean"
      version = "~> 1.0"
    }
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = "~> 1.0"
    }
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1.0"
    }
  }
}

source "amazon-ebs" "main" {
  # Auth/region to be handled by env vars
  ami_description       = "${var.app_name} - built by Packer on ${timestamp()}"
  ami_name              = "osc-${var.app_name}"
  force_delete_snapshot = true
  force_deregister      = true
  spot_instance_types   = ["t3a.micro"]
  spot_price            = "auto"
  ssh_interface         = var.ssh_interface # currently required if you want public connectivity because successful Spot requests try to connect via PRIVATE IP by default; https://github.com/hashicorp/packer/issues/10347
  ssh_username          = local.ssh_username
  ssh_wait_timeout      = local.ssh_wait_timeout

  temporary_security_group_source_cidrs = ["${var.my_ip}/32"]

  ami_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = var.volume_size
  }

  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = var.volume_size
  }

  source_ami_filter {
    filters = {
      # Ymir & ... start from Debian base, others start from Ymir (or another base from Ymir)
      name             = local.source_ami_name_pattern
      root-device-type = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = [local.source_ami_owner_id]
  }

  subnet_filter {
    filters = {
      "tag:Name"     = var.subnet_name_tag
      "tag:osc:core" = "true"
    }
    most_free = true
    random    = true
  }

  vpc_filter {
    filters = {
      "tag:Name"     = var.vpc_name_tag
      "tag:osc:core" = "true"
      "isDefault"    = false
    }
  }

  tags = {
    Name       = "osc-${var.app_name}"
    "osc:core" = "true"
    built_by   = "Packer"
  }

  run_tags = {
    Name       = "Packer Temp Builder - ${var.app_name}"
    "osc:core" = "true"
  }

  # Need BOTH of these for Spot Instance requests to work; bug in the provider:
  # https://github.com/hashicorp/packer-plugin-amazon/issues/92
  fleet_tags = {
    "osc:core" = "true"
  }
  spot_tags = {
    "osc:core" = "true"
  }
}

source "digitalocean" "main" {
  api_token          = var.do_api_token
  image              = "debian-${var.os_version_major}-x64"
  private_networking = true
  region             = var.do_region
  size               = var.do_droplet_size
  snapshot_name      = "aether"
  ssh_username       = "root"
  vpc_uuid           = var.do_vpc_id
}

# This requires some post-install Proxmox setup:
# - A Packer user, with requisite permissions in Proxmox
# - Your Proxmox host's vmbr0 bridge interface to have the VLAN-aware checkbox enabled
source "proxmox-iso" "main" {
  boot_command = local.boot_command
  cpu_type     = "host"
  disks {
    type              = "scsi"
    disk_size         = "10G"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm"
  }
  http_directory           = local.http_directory
  insecure_skip_tls_verify = var.proxmox_skip_tls_verify
  iso_checksum             = local.iso_checksum
  iso_file                 = "${var.proxmox_iso_storage_pool}:iso/${var.proxmox_stored_iso_file_name}"
  iso_storage_pool         = var.proxmox_iso_storage_pool
  memory                   = 1024
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  node             = var.proxmox_node
  password         = var.proxmox_password
  proxmox_url      = var.proxmox_url
  ssh_password     = local.ssh_password
  ssh_username     = local.ssh_username
  ssh_wait_timeout = local.ssh_wait_timeout
  # task_timeout         = "10m"
  template_description = "${var.app_name}. Generated on ${timestamp()}."
  template_name        = local.vm_name
  unmount_iso          = true
  username             = var.proxmox_username
}

source "proxmox-clone" "main" {
  # This expects the clone/start point to be done off of Ymir's premade VM template
  clone_vm = replace(local.vm_name, var.app_name, "ymir")
  cpu_type = "host"
  # disks {
  #   type              = "scsi"
  #   disk_size         = "10G"
  #   storage_pool      = "local-lvm"
  #   storage_pool_type = "lvm"
  # }
  full_clone               = false
  http_directory           = local.http_directory
  insecure_skip_tls_verify = var.proxmox_skip_tls_verify
  memory                   = 1024
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  node             = var.proxmox_node
  onboot           = true
  password         = var.proxmox_password
  proxmox_url      = var.proxmox_url
  ssh_password     = local.ssh_password
  ssh_username     = local.ssh_username
  ssh_wait_timeout = local.ssh_wait_timeout
  # task_timeout         = "10m"
  template_description = "${var.app_name}. Generated on ${timestamp()}."
  template_name        = local.vm_name
  username             = var.proxmox_username
}

source "virtualbox-iso" "main" {
  boot_command     = local.boot_command
  disk_size        = 10240
  guest_os_type    = "Linux_64"
  headless         = local.headless
  http_directory   = local.http_directory
  iso_checksum     = local.iso_checksum
  iso_url          = local.iso_url
  output_directory = "output-virtualbox-iso-${var.app_name}"
  shutdown_command = local.shutdown_command
  ssh_password     = local.ssh_password
  ssh_port         = local.ssh_port
  ssh_username     = local.ssh_username
  ssh_wait_timeout = local.ssh_wait_timeout
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--memory", "${var.virtualbox_memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "1"],
    ["modifyvm", "{{ .Name }}", "--vram", "128"],
    ["modifyvm", "{{ .Name }}", "--nic1", "nat"],
    ["modifyvm", "{{ .Name }}", "--nic2", "hostonly", "--hostonlyadapter2", "vboxnet0"]
  ]
  vm_name = local.vm_name
}

source "virtualbox-ovf" "main" {
  headless         = local.headless
  source_path      = local.virtualbox_ovf_path
  output_directory = "output-virtualbox-ovf-${var.app_name}"
  shutdown_command = local.shutdown_command
  ssh_password     = local.ssh_password
  ssh_port         = local.ssh_port
  ssh_username     = local.ssh_username
  ssh_wait_timeout = local.ssh_wait_timeout
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--memory", "${var.virtualbox_memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "1"],
    ["modifyvm", "{{ .Name }}", "--vram", "128"],
    ["modifyvm", "{{ .Name }}", "--nic1", "nat"],
    ["modifyvm", "{{ .Name }}", "--nic2", "hostonly", "--hostonlyadapter2", "vboxnet0"]
  ]
  vm_name = local.vm_name
}

build {
  sources = [
    "source.amazon-ebs.main",
    "source.digitalocean.main",
    "source.proxmox-clone.main",
    "source.proxmox-iso.main",
    "source.virtualbox-ovf.main",
    "source.virtualbox-iso.main"
  ]

  # Make a no-root-needed staging area for uploaded source files/directories,
  # and then copy them up -- first Ymir's common files, and then any optional
  # other ones provided by apps
  provisioner "shell" {
    execute_command = local.execute_command
    inline = [
      "mkdir -p /tmp/source_files/ymir",
      "chmod -R 0777 /tmp/source_files"
    ]
  }
  provisioner "file" {
    sources     = ["./scripts"]
    destination = "/tmp/source_files/ymir/"
  }
  provisioner "shell" {
    execute_command = local.execute_command
    inline = [
      "cp -r /tmp/source_files/ymir /usr/local/"
    ]
  }
  provisioner "file" {
    sources     = var.source_files
    destination = "/tmp/source_files/"
  }

  # Set up the second network interface for VirtualBox
  provisioner "shell" {
    execute_command = local.execute_command
    inline = [
      "bash /usr/local/ymir/scripts/build/virtualbox-network-setup.sh"
    ]
    only = ["virtualbox-iso.main", "virtualbox-ovf.main"]
  }

  # Run the build script provided by Ymir
  provisioner "shell" {
    environment_vars = [
      "app_name=${var.app_name}",
      "aether_address=${var.aether_address}"
    ]
    execute_command = local.execute_command
    inline = [
      "sleep ${var.build_delay}",
      "bash /usr/local/ymir/scripts/build/main.sh"
    ]
  }

  # Let build user (e.g. 'packer') run sudo without a password for VBox images
  provisioner "shell" {
    execute_command = local.execute_command
    inline = [
      "echo '${local.ssh_username} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
    ]
    only = ["virtualbox-iso.main", "virtualbox-ovf.main"]
  }

  # Tear down the second network interface for VirtualBox
  provisioner "shell" {
    execute_command = local.execute_command
    inline = [
      "bash /usr/local/ymir/scripts/build/virtualbox-network-setup.sh down"
    ]
    only = ["virtualbox-iso.main", "virtualbox-ovf.main"]
  }

  post-processor "vagrant" {
    keep_input_artifact = true
    output              = "output-vagrant-${var.app_name}/${var.app_name}.box"
    only                = ["virtualbox-iso.main", "virtualbox-ovf.main"]
  }
}
