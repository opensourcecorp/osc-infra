resource "aws_security_group" "main" {
  description = var.app_name
  name        = var.app_name
  vpc_id      = data.aws_vpc.main.id

  tags = merge(
    { Name = var.app_name },
    local.default_tags
  )
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  description       = "Allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "ping" {
  type              = "ingress"
  description       = "Ping from everywhere"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "deployer_ssh" {
  type              = "ingress"
  description       = "SSH from deployer IP"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.my_ip.body)}/32"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "custom" {
  count = length(var.sg_rules_maplist)

  type              = "ingress"
  description       = "${var.app_name} custom ingress"
  from_port         = var.sg_rules_maplist[count.index].port
  to_port           = var.sg_rules_maplist[count.index].port
  protocol          = var.sg_rules_maplist[count.index].protocol
  cidr_blocks       = var.sg_rules_maplist[count.index].cidr_blocks
  security_group_id = aws_security_group.main.id
}
