resource "aws_security_group" "" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = aws_vpc.main.ipv6_cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}





########



resource "aws_security_group_rule" "ping" {
  type              = "ingress"
  description       = "Ping from deployer IP" # TODO: this should be a wider subnet, but some environments throw security errors about it being on 0.0.0.0/0, like it was before
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["${chomp(data.http.my_ip.response_body)}/32"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "deployer_ssh" {
  type              = "ingress"
  description       = "SSH from deployer IP"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.my_ip.response_body)}/32"]
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
