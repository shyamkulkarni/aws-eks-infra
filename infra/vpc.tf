resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, { Name = "${var.project_name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.project_name}-igw" })
}

# Public subnets across AZs
resource "aws_subnet" "public" {
  for_each                = toset(slice(var.public_subnet_cidrs, 0, var.az_count))
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[index(keys(aws_subnet.public), each.key)]
  tags = merge(var.tags, {
    Name                                         = "${var.project_name}-public-${each.key}"
    "kubernetes.io/role/elb"                     = "1"
    "kubernetes.io/cluster/${var.project_name}"  = "shared"
  })
}

# NAT per AZ for resilience (you may switch to 1 NAT to save cost)
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "${var.project_name}-nat-eip-${each.key}" })
}

resource "aws_nat_gateway" "this" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags          = merge(var.tags, { Name = "${var.project_name}-nat-${each.key}" })
}

# Private subnets
resource "aws_subnet" "private" {
  for_each          = toset(slice(var.private_subnet_cidrs, 0, var.az_count))
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[index(keys(aws_subnet.private), each.key)]
  tags = merge(var.tags, {
    Name                                         = "${var.project_name}-private-${each.key}"
    "kubernetes.io/role/internal-elb"            = "1"
    "kubernetes.io/cluster/${var.project_name}"  = "shared"
  })
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.project_name}-rt-public" })
}
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = aws_nat_gateway.this
  vpc_id   = aws_vpc.this.id
  tags     = merge(var.tags, { Name = "${var.project_name}-rt-private-${each.key}" })
}
resource "aws_route" "private_nat" {
  for_each               = aws_route_table.private
  route_table_id         = each.value.id
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

data "aws_availability_zones" "available" {}