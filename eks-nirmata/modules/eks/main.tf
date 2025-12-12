#############################################
# EKS Cluster
#############################################
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = var.existing_cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.security_group_ids
    endpoint_public_access  = false
    endpoint_private_access = true
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  # Kubernetes version upgrade policy
  # STANDARD = 14 months support (default)
  # EXTENDED = 26 months support (additional cost)
  upgrade_policy {
    support_type = "STANDARD"
  }

  tags = {
    Name        = var.cluster_name
    Environment = "Dev"
    EKSVersion  = var.cluster_version
  }
}

#############################################
# Launch Template for EKS 1.33 (AL2023)
# Uses nodeadm instead of bootstrap.sh
#############################################
resource "aws_launch_template" "eks_nodes" {
  name_prefix   = var.launch_template_name
  image_id      = var.ami_id
  instance_type = var.instance_type
  # key_name      = var.key_pair_name  # Commented out - no SSH access

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 required for AL2023
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  vpc_security_group_ids = concat(
    var.security_group_ids,
    [aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id]
  )

  tags = {
    Name        = "LT-EKS-1.33-AL2023"
    Environment = "Dev"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.cluster_name}-node"
      Environment = "Dev"
      EKSVersion  = var.cluster_version
    }
  }

  # AL2023 nodeadm configuration (replaces bootstrap.sh)
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    clusterName          = aws_eks_cluster.eks_cluster.name
    apiServerEndpoint    = aws_eks_cluster.eks_cluster.endpoint
    certificateAuthority = aws_eks_cluster.eks_cluster.certificate_authority[0].data
    serviceCidr          = aws_eks_cluster.eks_cluster.kubernetes_network_config[0].service_ipv4_cidr
  }))

  lifecycle {
    create_before_destroy = true
  }
}

#############################################
# EKS Node Group
#############################################
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = var.existing_node_role_arn
  subnet_ids      = var.subnet_ids

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name        = "${var.cluster_name}-node-group"
    Environment = "Dev"
    EKSVersion  = var.cluster_version
  }

  depends_on = [aws_eks_cluster.eks_cluster]
}

#############################################
# EKS Access Entry for Admin
#############################################
resource "aws_eks_access_entry" "app_admin" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = var.iam_role_arn
}

resource "aws_eks_access_policy_association" "app_admin_clusteradmin" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = var.iam_role_arn

  access_scope {
    type = "cluster"
  }

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}

#############################################
# Local Variables for Outputs
#############################################
locals {
  eks_cluster_name                       = aws_eks_cluster.eks_cluster.name
  eks_cluster_endpoint                   = aws_eks_cluster.eks_cluster.endpoint
  eks_cluster_certificate_authority_data = aws_eks_cluster.eks_cluster.certificate_authority[0].data
  eks_cluster_security_group_id          = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

