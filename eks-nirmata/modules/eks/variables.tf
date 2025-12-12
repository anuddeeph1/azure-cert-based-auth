#############################################
# Cluster Variables
#############################################
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster (alias for cluster_name)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.33"
}

#############################################
# Network Variables
#############################################
variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
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
  description = "IAM role ARN for the EKS cluster"
  type        = string
}

variable "existing_node_role_arn" {
  description = "IAM role ARN for the EKS node group"
  type        = string
}

variable "iam_role_arn" {
  description = "IAM role/user ARN for access control"
  type        = string
}

#############################################
# Node Configuration Variables
#############################################
variable "launch_template_name" {
  description = "Prefix for the EC2 launch template name"
  type        = string
  default     = "eks-1.33-lt-"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances (use AL2023 EKS-optimized for 1.33)"
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

#############################################
# Scaling Variables
#############################################
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
# Legacy Variables (for backwards compatibility)
#############################################
variable "s3_bucket_name" {
  description = "S3 bucket name (legacy - not used with AL2023/nodeadm)"
  type        = string
  default     = ""
}

