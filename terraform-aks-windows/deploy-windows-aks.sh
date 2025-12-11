#!/bin/bash

# Deploy Windows AKS Cluster with Terraform
# Uses certificate-based authentication

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"
CERT_PATH="$SCRIPT_DIR/../certs/service-principal-combined.pem"

echo "=========================================="
echo "Windows AKS Cluster Deployment"
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "✗ Terraform not found. Install: brew install terraform"
    exit 1
fi
echo "✓ Terraform installed"

if ! command -v az &> /dev/null; then
    echo "✗ Azure CLI not found. Install: brew install azure-cli"
    exit 1
fi
echo "✓ Azure CLI installed"

if [ ! -f "$CERT_PATH" ]; then
    echo "✗ Certificate not found: $CERT_PATH"
    exit 1
fi
echo "✓ Certificate found"

echo ""
echo "=========================================="
echo "Step 1: Azure Authentication"
echo "=========================================="

if az account show &>/dev/null; then
    echo "Already logged in"
    az account show --output table
    echo ""
    read -p "Use this account? (y/n): " USE_CURRENT
    if [ "$USE_CURRENT" != "y" ]; then
        az logout
    fi
fi

if ! az account show &>/dev/null; then
    echo "Logging in with certificate..."
    az login --service-principal \
        --username 042aea62-c886-46a1-b2f8-25c9af22a2db \
        --tenant 3d95acd6-b6ee-428e-a7a0-196120fc3c65 \
        --certificate "$CERT_PATH"
fi

echo "✓ Authenticated"

echo ""
echo "=========================================="
echo "Step 2: Review Configuration"
echo "=========================================="

cd "$TERRAFORM_DIR"

echo "Configuration:"
grep -E "^(cluster_name|location|windows_node_pool|linux_node_pool)" terraform.tfvars | sed 's/^/  /'

echo ""
read -p "Edit configuration? (y/n): " EDIT_CONFIG
if [ "$EDIT_CONFIG" = "y" ]; then
    ${EDITOR:-vi} terraform.tfvars
fi

echo ""
echo "=========================================="
echo "Step 3: Terraform Initialize"
echo "=========================================="

terraform init

echo ""
echo "=========================================="
echo "Step 4: Terraform Validate"
echo "=========================================="

terraform validate

echo ""
echo "=========================================="
echo "Step 5: Terraform Plan"
echo "=========================================="

terraform plan -out=tfplan

echo ""
echo "=========================================="
echo "Review Plan"
echo "=========================================="
echo ""
echo "⚠️  IMPORTANT NOTES:"
echo "  • Windows nodes take 5-10 minutes to provision"
echo "  • Linux pool is required (cannot be removed)"
echo "  • Windows admin password will be auto-generated"
echo ""
read -p "Proceed with deployment? (yes/no): " PROCEED

if [ "$PROCEED" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo "=========================================="
echo "Step 6: Terraform Apply"
echo "=========================================="
echo "⏱️  This will take 20-25 minutes..."
echo ""

terraform apply tfplan

echo ""
echo "=========================================="
echo "Step 7: Get Credentials"
echo "=========================================="

CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
RG_NAME=$(terraform output -raw resource_group_name)

echo "Cluster: $CLUSTER_NAME"
echo "Resource Group: $RG_NAME"
echo ""

az aks get-credentials \
    --resource-group "$RG_NAME" \
    --name "$CLUSTER_NAME" \
    --overwrite-existing

echo ""
echo "=========================================="
echo "Step 8: Verify Deployment"
echo "=========================================="

echo "Nodes:"
kubectl get nodes -o wide

echo ""
echo "Node Pools:"
az aks nodepool list \
    --resource-group "$RG_NAME" \
    --cluster-name "$CLUSTER_NAME" \
    --output table

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT SUCCESSFUL!"
echo "=========================================="
echo ""

terraform output deployment_summary

echo ""
echo "Windows Admin Password:"
echo "Run: terraform output windows_admin_password"
echo ""
echo "⚠️  PRIVATE CLUSTER: Access via Jump Box or az aks command invoke"
echo ""

