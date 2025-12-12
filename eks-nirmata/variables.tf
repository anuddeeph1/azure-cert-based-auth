#############################################
# AWS Provider Variables
#############################################
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
}

#############################################
# EKS Cluster Variables
#############################################
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster (1.33 uses AL2023)"
  type        = string
  default     = "1.33"
}

#############################################
# Network Variables
#############################################
variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster and node group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the cluster and nodes"
  type        = list(string)
}

#############################################
# IAM Variables
#############################################
variable "existing_cluster_role_arn" {
  description = "ARN of existing IAM role for EKS cluster"
  type        = string
}

variable "existing_node_role_arn" {
  description = "ARN of existing IAM role for EKS node group"
  type        = string
}

variable "iam_role_arn" {
  description = "IAM role/user ARN for EKS cluster access control"
  type        = string
}

#############################################
# Node Group Variables
#############################################
variable "launch_template_name" {
  description = "Prefix for the EC2 launch template name"
  type        = string
  default     = "eks-1.33-lt-"
}

variable "ami_id" {
  description = "AMI ID for EKS nodes (use AL2023 EKS-optimized AMI for 1.33)"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the EC2 nodes"
  type        = string
  default     = "t3a.medium"
}

variable "key_pair_name" {
  description = "Key pair name for SSH access to EC2 nodes (optional)"
  type        = string
  default     = ""
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

#############################################
# Nirmata Variables
#############################################
variable "nirmata_token" {
  description = "API token for Nirmata authentication"
  type        = string
  sensitive   = true
}

variable "nirmata_url" {
  description = "URL for the Nirmata environment"
  type        = string
  default     = "https://nirmata.io"
}

variable "nirmata_cluster_name" {
  description = "Name of the cluster as it will appear in Nirmata"
  type        = string
}

variable "nirmata_cluster_type" {
  description = "Nirmata cluster type for policy management"
  type        = string
  default     = "default-addons-type"
}

#############################################
# Legacy Variables (backwards compatibility)
#############################################
variable "s3_bucket_name" {
  description = "S3 bucket name (legacy - not used with AL2023/nodeadm but kept for compatibility)"
  type        = string
  default     = ""
}

