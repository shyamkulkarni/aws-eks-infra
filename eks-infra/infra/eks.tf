resource "aws_iam_role" "eks_cluster" {
  name               = "${var.project_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
  tags               = var.tags
}
data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service" identifiers = ["eks.amazonaws.com"] }
  }
}
resource "aws_iam_role_policy_attachment" "eks_service" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node" {
  name               = "${var.project_name}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = var.tags
}
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service" identifiers = ["ec2.amazonaws.com"] }
  }
}
resource "aws_iam_role_policy_attachment" "worker_node" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "cni" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_cluster" "this" {
  name     = var.project_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.30" # pick latest supported

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"] # tighten later
    subnet_ids              = concat(values(aws_subnet.public)[*].id, values(aws_subnet.private)[*].id)
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_service
  ]
}

resource "aws_eks_node_group" "on_demand" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "ondemand"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = values(aws_subnet.private)[*].id

  scaling_config {
    min_size     = var.ng_on_demand_min
    max_size     = var.ng_on_demand_max
    desired_size = var.ng_on_demand_desired
  }

  ami_type       = "AL2_ARM_64"     # Graviton for cost; change to AL2_x86_64 if needed
  instance_types = var.instance_types_on_demand

  capacity_type = "ON_DEMAND"
  tags          = var.tags
}

resource "aws_eks_node_group" "spot" {
  count          = var.ng_spot_enabled ? 1 : 0
  cluster_name   = aws_eks_cluster.this.name
  node_group_name= "spot"
  node_role_arn  = aws_iam_role.eks_node.arn
  subnet_ids     = values(aws_subnet.private)[*].id

  scaling_config {
    min_size     = var.ng_spot_min
    max_size     = var.ng_spot_max
    desired_size = var.ng_spot_desired
  }

  ami_type       = "AL2_ARM_64"
  instance_types = var.instance_types_spot
  capacity_type  = "SPOT"
  tags           = var.tags
}

# OIDC provider for IRSA
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# Kube auth data sources
data "aws_eks_cluster" "this" { name = aws_eks_cluster.this.name }
data "aws_eks_cluster_auth" "this" { name = aws_eks_cluster.this.name }