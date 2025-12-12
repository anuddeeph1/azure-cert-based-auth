#############################################
# Nirmata Configuration
#############################################
nirmata_token        = "GU4XLFKtCP1w8v3R3rv30qD6PLEOR7dbtYtM2yck5AzTfJOGSnmxTH3X0DVeEF1xSyr8qgmtbCjw9ki8ZKMJOw=="
nirmata_url          = "https://nirmata.io"
nirmata_cluster_name = "eks-133-cluster"
nirmata_cluster_type = "default-add-ons"

#############################################
# EKS Cluster Configuration
#############################################
cluster_name    = "eks-133-cluster"
cluster_version = "1.33"

#############################################
# AWS Configuration
#############################################
aws_region  = "us-west-1"
aws_profile = "devtest"

#############################################
# Network Configuration
#############################################
vpc_id     = "vpc-00f2eeea72144b5c2 "
subnet_ids = ["subnet-072a174d80bf20518", "subnet-099cf43da4da28eab"]

security_group_ids = [
  "sg-0833ddfff3b608a45",
  "sg-0caa3c350f37ad751"
]

#############################################
# IAM Roles
#############################################
existing_cluster_role_arn = "arn:aws:iam::844333597536:role/eksClusterRole-anudeep"
existing_node_role_arn    = "arn:aws:iam::844333597536:role/eks-anudeep-worker-node"
iam_role_arn              = "arn:aws:iam::844333597536:user/anudeep"

#############################################
# Node Configuration
# NOTE: For EKS 1.33, use AL2023 AMI. Get the latest AMI ID with:
#   aws ssm get-parameter \
#     --name "/aws/service/eks/optimized-ami/1.33/amazon-linux-2023/x86_64/standard/recommended/image_id" \
#     --region us-west-1 --profile devtest \
#     --query "Parameter.Value" --output text
#############################################
launch_template_name = "eks-1.33-lt-novartis"
ami_id               = "ami-09db1f6885a2a341f"  # EKS 1.33 AL2023 AMI for us-west-1
instance_type        = "t3a.medium"
# key_pair_name        = "terraform-eks"  # Commented out - no SSH access to nodes

#############################################
# Node Group Scaling
#############################################
desired_size = 2
min_size     = 1
max_size     = 3

#############################################
# Legacy (not used with AL2023 but kept for compatibility)
#############################################
#s3_bucket_name = ""

