#############################################
# EKS Cluster Outputs
#############################################
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS API server"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID created by EKS for the cluster"
  value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.version
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.arn
}

output "node_group_name" {
  description = "Name of the EKS node group"
  value       = aws_eks_node_group.eks_node_group.node_group_name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.eks_nodes.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.eks_nodes.latest_version
}

