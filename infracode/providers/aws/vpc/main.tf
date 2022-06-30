#################
# Core / Shared #
#################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = local.tags
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "common" {
  description = "Common rules for OpenSourceCorp resources"
  name        = "${var.name_tag}_common"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.tags,
    { Name = "${var.name_tag}_common" }
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
  security_group_id = aws_security_group.common.id
}

resource "aws_security_group_rule" "prometheus_node_exporter" {
  type              = "ingress"
  description       = "Allow Monitoring"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.common.id
}

##########
# Public #
##########
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = local.tags
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_subnet" "public" {
  count = local.n_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    { Name = "${var.name_tag}_public" }
  )
}

resource "aws_route_table_association" "public" {
  count = local.n_subnets

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

###########
# Private #
###########
resource "aws_eip" "nat_gateway" {
  count      = var.use_private_subnets ? 1 : 0
  depends_on = [aws_internet_gateway.main]

  tags = local.tags
}

resource "aws_nat_gateway" "main" {
  count      = var.use_private_subnets ? 1 : 0
  depends_on = [aws_internet_gateway.main]

  allocation_id = aws_eip.nat_gateway[0].id
  subnet_id     = aws_subnet.public[0].id # just use the first one

  tags = local.tags
}

resource "aws_route_table" "private" {
  count = var.use_private_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = local.tags
}

resource "aws_route" "private" {
  count = var.use_private_subnets ? 1 : 0

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
  route_table_id         = aws_route_table.private[0].id
}

resource "aws_subnet" "private" {
  count = var.use_private_subnets ? local.n_subnets : 0

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${local.n_subnets + count.index + 1}.0/24"
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.main.id

  tags = merge(
    local.tags,
    { Name = "${var.name_tag}_private" }
  )
}

resource "aws_route_table_association" "private" {
  count = var.use_private_subnets ? local.n_subnets : 0

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}
