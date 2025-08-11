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
  availability_zone       = data.aws_availability_zones.available.names[index(var.public_subnet_cidrs, each.value)]
  tags = merge(var.tags, {
    Name                                         = "${var.project_name}-public-${each.key}"
    "kubernetes.io/role/elb"                     = "1"
    "kubernetes.io/cluster/${var.project_name}"  = "shared"
  })
}

# Single NAT gateway to avoid EIP limit and save cost
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.project_name}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id
  tags          = merge(var.tags, { Name = "${var.project_name}-nat" })
}

# Private subnets
resource "aws_subnet" "private" {
  for_each          = toset(slice(var.private_subnet_cidrs, 0, var.az_count))
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[index(var.private_subnet_cidrs, each.value)]
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
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.project_name}-rt-private" })
}
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

data "aws_availability_zones" "available" {}

# Security Groups
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.project_name}-eks-cluster-"
  vpc_id      = aws_vpc.this.id
  description = "Security group for EKS cluster control plane"
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, { Name = "${var.project_name}-eks-cluster-sg" })
}

resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project_name}-eks-nodes-"
  vpc_id      = aws_vpc.this.id
  description = "Security group for EKS worker nodes"
  
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "Allow cluster control plane to communicate with worker nodes"
  }
  
  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "Allow cluster control plane to communicate with worker nodes (kubelet)"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, { Name = "${var.project_name}-eks-nodes-sg" })
}