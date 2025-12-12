#############################################
# EKS Cluster Outputs
#############################################
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = var.cluster_version
}

#############################################
# Utility Outputs
#############################################
output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name} --profile ${var.aws_profile}"
}

output "get_ami_command" {
  description = "Command to get latest EKS 1.33 AL2023 AMI ID"
  value       = "aws ssm get-parameter --name \"/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id\" --region ${var.aws_region} --profile ${var.aws_profile} --query \"Parameter.Value\" --output text"
}

#############################################
# Nirmata Outputs
#############################################
output "nirmata_controller_yamls_folder" {
  description = "Folder containing Nirmata controller YAML files"
  value       = nirmata_cluster_registered.eks-registered.controller_yamls_folder
}

output "nirmata_controller_ns_yamls_count" {
  description = "Number of namespace YAML files"
  value       = nirmata_cluster_registered.eks-registered.controller_ns_yamls_count
}

output "nirmata_controller_sa_yamls_count" {
  description = "Number of service account YAML files"
  value       = nirmata_cluster_registered.eks-registered.controller_sa_yamls_count
}

output "nirmata_controller_crd_yamls_count" {
  description = "Number of CRD YAML files"
  value       = nirmata_cluster_registered.eks-registered.controller_crd_yamls_count
}

output "nirmata_controller_deploy_yamls_count" {
  description = "Number of deployment YAML files"
  value       = nirmata_cluster_registered.eks-registered.controller_deploy_yamls_count
}

