#!/bin/bash

# Deploy Private AKS Cluster with Terraform
# Uses certificate-based authentication

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"
CERT_PATH="$SCRIPT_DIR/../certs/service-principal-combined.pem"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Private AKS Cluster Deployment"
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗ Terraform not found${NC}"
    echo "Install: brew install terraform"
    exit 1
fi
echo -e "${GREEN}✓ Terraform installed${NC} ($(terraform version | head -1))"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}✗ Azure CLI not found${NC}"
    echo "Install: brew install azure-cli"
    exit 1
fi
echo -e "${GREEN}✓ Azure CLI installed${NC} ($(az version -o json | jq -r '."azure-cli"'))"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl not found${NC}"
    echo "Install: brew install kubectl"
    exit 1
fi
echo -e "${GREEN}✓ kubectl installed${NC} ($(kubectl version --client --short 2>/dev/null || echo 'installed'))"

# Check certificate
if [ ! -f "$CERT_PATH" ]; then
    echo -e "${RED}✗ Certificate not found: $CERT_PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Certificate found${NC}"

echo ""
echo "=========================================="
echo "Step 1: Azure Authentication"
echo "=========================================="

# Check if already logged in
if az account show &>/dev/null; then
    echo -e "${YELLOW}Already logged in to Azure${NC}"
    az account show --output table
    echo ""
    read -p "Use this account? (y/n): " USE_CURRENT
    if [ "$USE_CURRENT" != "y" ] && [ "$USE_CURRENT" != "Y" ]; then
        az logout
    fi
fi

# Login if not already logged in
if ! az account show &>/dev/null; then
    echo "Logging in with certificate..."
    az login --service-principal \
        --username 042aea62-c886-46a1-b2f8-25c9af22a2db \
        --tenant 3d95acd6-b6ee-428e-a7a0-196120fc3c65 \
        --certificate "$CERT_PATH"
fi

echo -e "${GREEN}✓ Authenticated${NC}"
az account show --output table

echo ""
echo "=========================================="
echo "Step 2: Review Configuration"
echo "=========================================="

cd "$TERRAFORM_DIR"

echo "Terraform configuration:"
echo "  Directory: $TERRAFORM_DIR"
echo "  Variables: terraform.tfvars"
echo ""

echo "Key settings:"
grep -E "^(cluster_name|location|enable_private_cluster|default_node_pool)" terraform.tfvars | sed 's/^/  /'

echo ""
read -p "Edit configuration before deploying? (y/n): " EDIT_CONFIG
if [ "$EDIT_CONFIG" = "y" ] || [ "$EDIT_CONFIG" = "Y" ]; then
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
echo -e "${YELLOW}=========================================="
echo "Review the plan above"
echo "==========================================${NC}"
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
echo -e "${YELLOW}This will take 15-20 minutes...${NC}"
echo ""

terraform apply tfplan

echo ""
echo "=========================================="
echo "Step 7: Get AKS Credentials"
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

echo "Checking cluster..."
kubectl cluster-info

echo ""
echo "Nodes:"
kubectl get nodes

echo ""
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
echo ""

terraform output

echo ""
echo -e "${GREEN}=========================================="
echo "✅ DEPLOYMENT SUCCESSFUL!"
echo "==========================================${NC}"
echo ""

IS_PRIVATE=$(terraform output -raw aks_is_private)
if [ "$IS_PRIVATE" = "true" ]; then
    echo -e "${YELLOW}⚠️  IMPORTANT: This is a PRIVATE cluster${NC}"
    echo ""
    echo "The API server is not publicly accessible."
    echo "You are currently able to access it because:"
    echo "  - You're on the same network, OR"
    echo "  - You have VPN access, OR"
    echo "  - Azure CLI is routing through Azure"
    echo ""
    echo "To access from other locations, you need:"
    echo "  1. Jump box VM in the same VNet"
    echo "  2. VPN connection to the VNet"
    echo "  3. Azure Bastion"
    echo ""
    echo "See TERRAFORM-LOCAL-DEPLOYMENT.md for details"
    echo ""
fi

echo "Next steps:"
echo "  1. Deploy applications: kubectl apply -f app.yaml"
echo "  2. View resources: kubectl get all --all-namespaces"
echo "  3. Access cluster: See documentation for private cluster access"
echo ""
echo "Documentation:"
echo "  - TERRAFORM-LOCAL-DEPLOYMENT.md"
echo "  - README.md"
echo ""
echo "Cluster details saved in: terraform.tfstate"
echo ""

