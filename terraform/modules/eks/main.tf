# --- IAM role for the EKS control plane ---
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- EKS cluster (control plane) ---
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true # console/kubectl access from outside the VPC; restrict via public_access_cidrs for production
    security_group_ids      = [var.eks_nodes_security_group_id]
  }

  # CloudWatch Container Insights log types - the control plane's own
  # logs (not pod logs), used by the monitoring module.
  enabled_cluster_log_types = ["api", "audit", "authenticator", "scheduler", "controllerManager"]

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# --- OIDC provider - required for IRSA (IAM Roles for Service Accounts),
# which is how pods (e.g. the backend's Secrets Manager access, or the
# AWS Load Balancer Controller) assume IAM roles without static keys ---
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  tags            = var.tags
}

# --- IAM role for worker nodes ---
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Add ECR read-only managed policy to ensure system pods can pull images
resource "aws_iam_role_policy_attachment" "node_ecr_managed" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
# Custom, least-privilege policy instead of the broad
# AmazonEC2ContainerRegistryReadOnly managed policy - scoped to only
# this project's two ECR repos.
resource "aws_iam_role_policy" "node_ecr_pull" {
  name = "${var.cluster_name}-ecr-pull"
  role = aws_iam_role.node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = var.ecr_repository_arns
      }
    ]
  })
}

# --- Managed node group (private subnets only - no public IP on nodes) ---
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-ng-default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = [var.node_instance_type]
  ami_type        = "AL2023_x86_64_STANDARD"

  scaling_config {
    desired_size = var.node_count
    min_size     = var.node_min_count
    max_size     = var.node_max_count
  }

  update_config {
    max_unavailable = 1 # rolling upgrade - never takes all nodes down at once
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size] # let the cluster autoscaler manage this day-to-day
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr_managed,
    aws_iam_role_policy.node_ecr_pull,
  ]
}
