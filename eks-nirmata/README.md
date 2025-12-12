# EKS 1.33 with Nirmata Integration

This Terraform configuration deploys an Amazon EKS 1.33 cluster with Nirmata integration for policy management.

## ⚠️ Important: EKS 1.33 Changes

**EKS 1.33 uses Amazon Linux 2023 (AL2023) instead of Amazon Linux 2 (AL2).** This introduces significant changes:

| Feature | AL2 (EKS ≤1.32) | AL2023 (EKS 1.33+) |
|---------|-----------------|---------------------|
| **Bootstrap** | `/etc/eks/bootstrap.sh` | `nodeadm` |
| **User Data** | Shell script | MIME multipart with NodeConfig YAML |
| **IMDSv2** | Optional | Required by default |
| **AMI Parameter** | `.../amazon-linux-2/...` | `.../amazon-linux-2023/...` |

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate profile
- kubectl installed
- Existing VPC with subnets
- Existing IAM roles for EKS cluster and nodes
- Nirmata API token

## Getting the EKS 1.33 AMI ID

**You must use an AL2023 AMI for EKS 1.33.** Run this command to get the latest AMI:

```bash
# For x86_64 instances
aws ssm get-parameter \
  --name "/aws/service/eks/optimized-ami/1.33/amazon-linux-2023/x86_64/standard/recommended/image_id" \
  --region us-west-1 \
  --profile devtest \
  --query "Parameter.Value" \
  --output text

# For ARM64 instances
aws ssm get-parameter \
  --name "/aws/service/eks/optimized-ami/1.33/amazon-linux-2023/arm64/standard/recommended/image_id" \
  --region us-west-1 \
  --profile devtest \
  --query "Parameter.Value" \
  --output text
```

## Directory Structure

```
eks-nirmata/
├── main.tf                    # Provider config and EKS module call
├── variables.tf               # All variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars           # Variable values (update before use)
├── nirmata.tf                 # Nirmata integration and controller deployment
├── README.md                  # This file
└── modules/
    └── eks/
        ├── main.tf            # EKS cluster, launch template, node group
        ├── variables.tf       # Module variables
        ├── outputs.tf         # Module outputs
        └── userdata.sh        # AL2023 nodeadm configuration
```

## Configuration

### 1. Update terraform.tfvars

Edit `terraform.tfvars` with your values:

```hcl
# Nirmata
nirmata_token        = "your-nirmata-api-token"
nirmata_url          = "https://nirmata.io"
nirmata_cluster_name = "my-eks-cluster"
nirmata_cluster_type = "default-addons-type"

# EKS Cluster
cluster_name    = "my-eks-cluster"
cluster_version = "1.33"

# AWS
aws_region  = "us-west-1"
aws_profile = "your-profile"

# Network
vpc_id     = "vpc-xxxxxxxxx"
subnet_ids = ["subnet-xxx", "subnet-yyy"]
security_group_ids = ["sg-xxx", "sg-yyy"]

# IAM Roles
existing_cluster_role_arn = "arn:aws:iam::ACCOUNT:role/EKSClusterRole"
existing_node_role_arn    = "arn:aws:iam::ACCOUNT:role/EKSNodeRole"
iam_role_arn              = "arn:aws:iam::ACCOUNT:user/your-user"

# Node Configuration - GET AMI ID USING COMMAND ABOVE
ami_id               = "ami-xxxxxxxxx"  # AL2023 AMI ID
instance_type        = "t3a.medium"
key_pair_name        = "your-key-pair"

# Scaling
desired_size = 2
min_size     = 1
max_size     = 3
```

### 2. Initialize and Apply

```bash
# Login to AWS SSO (if using SSO)
aws sso login --profile devtest

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## User Data Configuration (AL2023 / nodeadm)

EKS 1.33 uses `nodeadm` for node bootstrapping. The user data is a MIME multipart document with a `NodeConfig` resource:

```yaml
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"

--BOUNDARY
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${clusterName}
    apiServerEndpoint: ${apiServerEndpoint}
    certificateAuthority: ${certificateAuthority}
    cidr: ${serviceCidr}

--BOUNDARY--
```

This replaces the old `bootstrap.sh` script used in AL2.

## Outputs

After successful deployment, you'll get:

- `cluster_name` - Name of the EKS cluster
- `cluster_endpoint` - EKS API server endpoint
- `cluster_security_group_id` - Cluster security group
- `kubeconfig_command` - Command to configure kubectl
- `get_ami_command` - Command to get latest AL2023 AMI
- Nirmata controller information

## Configuring kubectl

```bash
# Use the output command or run:
aws eks update-kubeconfig \
  --region us-west-1 \
  --name my-eks-cluster \
  --profile devtest

# Verify connection
kubectl get nodes
kubectl get pods -A
```

## Troubleshooting

### Nodes Not Joining Cluster

1. Verify you're using an AL2023 AMI (not AL2)
2. Check node role has required policies:
   - `AmazonEKSWorkerNodePolicy`
   - `AmazonEC2ContainerRegistryReadOnly`
   - `AmazonEKS_CNI_Policy`
3. Verify security groups allow required traffic

### IMDSv2 Issues

AL2023 requires IMDSv2 by default. The launch template is configured correctly, but verify your applications can work with IMDSv2.

### Nirmata Controller Issues

1. Check kubectl is configured correctly
2. Verify Nirmata token is valid
3. Review controller YAML files in the output folder

## Clean Up

```bash
terraform destroy
```

## References

- [EKS 1.33 Release Notes](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)
- [AL2023 Migration Guide](https://docs.aws.amazon.com/eks/latest/userguide/al2023.html)
- [nodeadm Configuration](https://awslabs.github.io/amazon-eks-ami/nodeadm/)
- [Nirmata Provider Documentation](https://registry.terraform.io/providers/nirmata/nirmata/latest/docs)

