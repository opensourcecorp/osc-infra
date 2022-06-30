# TODO: add support for non-Spot instances

resource "aws_spot_instance_request" "main" {
  count = var.use_spot_instance ? 1 : 0

  # Assumes that you're not running this for jobs, but for long-lived services
  instance_interruption_behavior = "stop"
  spot_type                      = "persistent"
  wait_for_fulfillment           = true

  ami                    = data.aws_ami.latest.id
  iam_instance_profile   = var.instance_profile_name != "" ? var.instance_profile_name : null
  instance_type          = var.instance_type
  key_name               = var.keypair_name != "" ? var.keypair_name : null
  subnet_id              = var.use_static_ip ? null : local.subnet_id
  # user_data              = <<-EOF
  #   #!/usr/bin/env bash
  #   export configmgmt_address=${var.configmgmt_address}
  #   export app_name=${var.app_name}
  #   bash /usr/local/baseimg/scripts/run/main.sh
  # EOF
  vpc_security_group_ids = var.use_static_ip ? null : local.sg_ids

  # To prevent unexpected shutdown of t3-family Spot instances 
  credit_specification {
    cpu_credits = "standard"
  }

  dynamic "network_interface" {
    for_each = var.use_static_ip ? [1] : []
    content {
      network_interface_id = aws_network_interface.static_ip[0].id
      device_index         = 0
    }
  }

  root_block_device {
    volume_size = var.volume_size
  }

  tags = merge(
    { Name = var.name_tag },
    local.default_tags
  )

  # Need this to apply tags to actual instances, since this resource can't do that itself
  # Also have to duplicate local.default_tags, since provisioners don't let you for_each, UGH
  provisioner "local-exec" {
    command = <<-EOF
      aws ec2 create-tags \
        --resources ${self.spot_instance_id} \
        --tags \
          Key=Name,Value=${var.name_tag} \
          Key=spot_request_id,Value=${self.id} \
          Key="osc:core",Value=${var.is_osc_core ? "true" : "false"} \
          Key=module_source,Value=https://github.com/opensourcecorp/osc-infra//infracode/providers/aws/ec2_instance \
          Key=deployment_source,Value=${var.source_address}
    EOF
  }

  connection {
    host        = self.public_ip
    private_key = file(pathexpand(var.keypair_local_file))
    user        = "admin"
  }

  # Set up Salt tree for configmgmt
  provisioner "local-exec" {
    command = <<-EOF
      if [ '${var.app_name}' = 'configmgmt' ]; then
        scp -i ${pathexpand(var.keypair_local_file)} -o StrictHostKeyChecking=no -r ../../salt admin@${self.public_ip}:/tmp
      fi
    EOF
  }

  provisioner "remote-exec" {
    inline = [<<-EOF
      export app_name='${var.app_name}'
      export configmgmt_address='10.0.1.10'
      [ -d /tmp/salt ] && /tmp/source_files/salt/* /srv/
      sudo -E bash /usr/local/baseimg/scripts/run/main.sh
    EOF
    ]
  }
}

resource "aws_network_interface" "static_ip" {
  count = var.use_static_ip ? 1 : 0

  private_ips     = var.desired_private_ip != "" ? [var.desired_private_ip] : null
  subnet_id       = local.subnet_id
  security_groups = local.sg_ids

  tags = merge(
    { Name = var.app_name },
    local.default_tags
  )
}

resource "aws_eip" "main" {
  count = var.use_static_ip ? 1 : 0

  associate_with_private_ip = var.desired_private_ip != "" ? var.desired_private_ip : null
  network_interface         = var.desired_private_ip != "" ? aws_network_interface.static_ip[0].id : null
  vpc                       = true

  tags = merge(
    { Name = var.name_tag },
    local.default_tags
  )
}

resource "aws_eip_association" "main" {
  count = var.use_static_ip ? 1 : 0

  allocation_id = aws_eip.main[0].id
  instance_id   = var.use_spot_instance ? aws_spot_instance_request.main[count.index].spot_instance_id : null # TODO: add support for non-Spot instances
}
