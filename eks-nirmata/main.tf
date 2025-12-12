#############################################
# EKS 1.33 with Nirmata Integration
# Terraform Configuration
#############################################

terraform {
  required_version = ">= 1.5.0"

  #############################################
  # S3 Backend for State Storage (COMMENTED OUT)
  # Uncomment and update bucket, key, region as needed
  #############################################
  # backend "s3" {
  #   bucket         = "novartisrdrar15dev-eks-bootstrap"  # Your S3 bucket name
  #   key            = "eks-1.33/terraform.tfstate"        # Path to state file in bucket
  #   region         = "us-west-1"                          # S3 bucket region
  #   encrypt        = true                                 # Enable encryption
  #   # Optional: DynamoDB table for state locking
  #   # dynamodb_table = "terraform-state-lock"
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.53"
    }
    nirmata = {
      source  = "nirmata/nirmata"
      version = "~> 1.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

#############################################
# AWS Provider
#############################################
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

#############################################
# EKS Cluster Module
#############################################
module "eks" {
  source = "./modules/eks"

  # Cluster Configuration
  cluster_name     = var.cluster_name
  eks_cluster_name = var.cluster_name
  cluster_version  = var.cluster_version

  # Network Configuration
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  # IAM Roles
  existing_cluster_role_arn = var.existing_cluster_role_arn
  existing_node_role_arn    = var.existing_node_role_arn
  iam_role_arn              = var.iam_role_arn

  # Node Configuration
  launch_template_name = var.launch_template_name
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  # key_pair_name        = var.key_pair_name  # Commented out - no SSH
  # s3_bucket_name       = var.s3_bucket_name

  # Scaling Configuration
  desired_size = var.desired_size
  min_size     = var.min_size
  max_size     = var.max_size
}

