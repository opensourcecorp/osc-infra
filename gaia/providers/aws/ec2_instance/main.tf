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
  # user_data              = var.user_data_filepath != "" ? file(var.user_data_filepath) : var.user_data_string
  user_data = <<-EOF
    #!/usr/bin/env bash
    export aether_address=${var.aether_address}
    export app_name=${var.app_name}
    bash /usr/local/ymir/scripts/run/main.sh
  EOF
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
    command = <<-SCRIPT
      aws ec2 create-tags \
        --resources ${self.spot_instance_id} \
        --tags \
          Key=Name,Value=${var.name_tag} \
          Key=spot_request_id,Value=${self.id} \
          Key="osc:core",Value=${var.is_osc_core ? "true" : "false"} \
          Key=module_source,Value=https://github.com/opensourcecorp/gaia//providers/aws/ec2_instance \
          Key=deployment_source,Value=${var.source_address}
    SCRIPT
    # # TODO: Figure out how to get this to work
    # environment = merge(
    #   { Name = var.name_tag },
    #   { spot_request_id = self.id },
    #   local.default_tags
    # )
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
