
# Discover the existing default VPC.

data "aws_vpc" "default_vpc" {
  default = true
}

# Create a public subnet in us-east-1b.

resource "aws_subnet" "eks_public_subnet_b" {
  vpc_id                  = data.aws_vpc.default_vpc.id
  cidr_block              = "172.31.16.0/20"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                                   = "${var.cluster_name}-public-us-east-1b"
    Project                                = "voting-app-capstone"
    Environment                            = "development"
    "kubernetes.io/role/elb"               = "1"
    "kubernetes.io/cluster/voting-app-eks" = "shared"
  }
}

# Create a public subnet in us-east-1c.

resource "aws_subnet" "eks_public_subnet_c" {
  vpc_id                  = data.aws_vpc.default_vpc.id
  cidr_block              = "172.31.32.0/20"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name                                   = "${var.cluster_name}-public-us-east-1c"
    Project                                = "voting-app-capstone"
    Environment                            = "development"
    "kubernetes.io/role/elb"               = "1"
    "kubernetes.io/cluster/voting-app-eks" = "shared"
  }
}

# IAM role for the EKS control plane.

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project     = "voting-app-capstone"
    Environment = "development"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM role for EC2 worker nodes.

resource "aws_iam_role" "eks_worker_node_role" {
  name = "${var.cluster_name}-worker-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project     = "voting-app-capstone"
    Environment = "development"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_cni_policy" {
  role       = aws_iam_role.eks_worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_ecr_readonly_policy" {
  role       = aws_iam_role.eks_worker_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS control plane.

resource "aws_eks_cluster" "voting_app_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.eks_public_subnet_b.id,
      aws_subnet.eks_public_subnet_c.id
    ]

    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  tags = {
    Project     = "voting-app-capstone"
    Environment = "development"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# Managed EC2 worker nodes.

resource "aws_eks_node_group" "voting_app_workers" {
  cluster_name    = aws_eks_cluster.voting_app_cluster.name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = aws_iam_role.eks_worker_node_role.arn

  subnet_ids = [
    aws_subnet.eks_public_subnet_b.id,
    aws_subnet.eks_public_subnet_c.id
  ]

  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Project     = "voting-app-capstone"
    Environment = "development"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_worker_cni_policy,
    aws_iam_role_policy_attachment.eks_worker_ecr_readonly_policy
  ]
}
