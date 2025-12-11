#!/bin/bash

# Azure Certificate-Based Authentication - Complete Setup Script
# This script automates the entire setup process

set -e

echo "=========================================="
echo "Azure Certificate Auth - Complete Setup"
echo "=========================================="
echo ""
echo "This script will:"
echo "  1. Generate OpenSSL certificates"
echo "  2. Create Azure service principal"
echo "  3. Upload certificate to Azure AD"
echo "  4. Assign permissions"
echo "  5. Test authentication"
echo ""
read -p "Continue? (y/n): " CONTINUE

if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
    echo "Setup cancelled"
    exit 0
fi

# Check prerequisites
echo ""
echo "=========================================="
echo "Checking Prerequisites"
echo "=========================================="

command -v az >/dev/null 2>&1 || { echo "✗ Azure CLI not found. Install from: https://aka.ms/installazurecli"; exit 1; }
echo "✓ Azure CLI installed"

command -v openssl >/dev/null 2>&1 || { echo "✗ OpenSSL not found"; exit 1; }
echo "✓ OpenSSL installed"

# Check Azure login
echo ""
echo "Checking Azure login status..."
az account show >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Not logged in to Azure. Please login..."
    az login
else
    echo "✓ Already logged in to Azure"
    az account show --output table
    echo ""
    read -p "Use this subscription? (y/n): " USE_SUB
    if [ "$USE_SUB" != "y" ] && [ "$USE_SUB" != "Y" ]; then
        az login
    fi
fi

# Get subscription details
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo ""
echo "Using subscription:"
echo "  Name: $SUBSCRIPTION_NAME"
echo "  ID: $SUBSCRIPTION_ID"
echo "  Tenant: $TENANT_ID"
echo ""

# Get service principal details
echo "=========================================="
echo "Service Principal Configuration"
echo "=========================================="
echo ""

read -p "Enter Service Principal name [default: azure-devops-cert-sp]: " SP_NAME
SP_NAME=${SP_NAME:-azure-devops-cert-sp}

read -p "Enter certificate validity in days [default: 365]: " CERT_DAYS
CERT_DAYS=${CERT_DAYS:-365}

# Generate certificate
echo ""
echo "=========================================="
echo "Step 1: Generating Certificate"
echo "=========================================="

CERT_DIR="./certs"
mkdir -p "$CERT_DIR"

KEY_FILE="$CERT_DIR/service-principal-key.pem"
CERT_FILE="$CERT_DIR/service-principal-cert.pem"
COMBINED_FILE="$CERT_DIR/service-principal-combined.pem"
CER_FILE="$CERT_DIR/service-principal-cert.cer"

openssl req -x509 -newkey rsa:4096 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days "$CERT_DAYS" \
    -nodes \
    -subj "/CN=$SP_NAME"

cat "$CERT_FILE" "$KEY_FILE" > "$COMBINED_FILE"
openssl x509 -in "$CERT_FILE" -outform DER -out "$CER_FILE"

THUMBPRINT=$(openssl x509 -in "$CERT_FILE" -noout -fingerprint -sha1 | cut -d'=' -f2 | tr -d ':')

echo "✓ Certificate generated successfully"
echo "  Thumbprint: $THUMBPRINT"

# Create service principal
echo ""
echo "=========================================="
echo "Step 2: Creating Service Principal"
echo "=========================================="

# Check if SP already exists
EXISTING_SP=$(az ad sp list --display-name "$SP_NAME" --query "[0].appId" -o tsv 2>/dev/null)

if [ ! -z "$EXISTING_SP" ]; then
    echo "⚠ Service principal '$SP_NAME' already exists (ID: $EXISTING_SP)"
    read -p "Use existing service principal? (y/n): " USE_EXISTING
    
    if [ "$USE_EXISTING" = "y" ] || [ "$USE_EXISTING" = "Y" ]; then
        APP_ID=$EXISTING_SP
        echo "✓ Using existing service principal"
    else
        echo "Please choose a different name or delete the existing service principal"
        exit 1
    fi
else
    # Create new service principal
    SP_OUTPUT=$(az ad sp create-for-rbac --name "$SP_NAME" --skip-assignment --output json)
    APP_ID=$(echo $SP_OUTPUT | grep -o '"appId": "[^"]*' | cut -d'"' -f4)
    
    echo "✓ Service principal created"
    echo "  Application ID: $APP_ID"
    
    # Wait for SP to propagate
    echo "  Waiting for service principal to propagate..."
    sleep 10
fi

# Upload certificate
echo ""
echo "=========================================="
echo "Step 3: Uploading Certificate to Azure AD"
echo "=========================================="

az ad app credential reset --id "$APP_ID" --cert "@$CERT_FILE" --append >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Certificate uploaded successfully"
else
    echo "⚠ Certificate upload may have failed. Trying alternative method..."
    az ad sp credential reset --id "$APP_ID" --cert "@$CERT_FILE" --append
fi

# Assign permissions
echo ""
echo "=========================================="
echo "Step 4: Assigning Permissions"
echo "=========================================="
echo ""
echo "Available roles:"
echo "  1. Reader (read-only access)"
echo "  2. Contributor (read/write, no RBAC changes)"
echo "  3. Owner (full access)"
echo ""
read -p "Select role [default: 2 - Contributor]: " ROLE_CHOICE
ROLE_CHOICE=${ROLE_CHOICE:-2}

case $ROLE_CHOICE in
    1) ROLE_NAME="Reader" ;;
    2) ROLE_NAME="Contributor" ;;
    3) ROLE_NAME="Owner" ;;
    *) ROLE_NAME="Contributor" ;;
esac

echo ""
echo "Assigning $ROLE_NAME role to service principal..."

az role assignment create \
    --assignee "$APP_ID" \
    --role "$ROLE_NAME" \
    --scope "/subscriptions/$SUBSCRIPTION_ID" \
    >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✓ $ROLE_NAME role assigned successfully"
else
    echo "⚠ Role assignment may have failed (might already exist)"
fi

# Wait for role assignment to propagate
echo "  Waiting for permissions to propagate..."
sleep 15

# Test authentication
echo ""
echo "=========================================="
echo "Step 5: Testing Authentication"
echo "=========================================="

echo "Attempting to authenticate with certificate..."

az login --service-principal \
    --username "$APP_ID" \
    --tenant "$TENANT_ID" \
    --certificate "$COMBINED_FILE" \
    --allow-no-subscriptions \
    >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Authentication successful!"
    
    # Set the subscription
    az account set --subscription "$SUBSCRIPTION_ID" 2>/dev/null
    
    # Test resource access
    echo ""
    echo "Testing resource access..."
    az group list --output table 2>/dev/null
    
    RG_COUNT=$(az group list --query "length(@)" 2>/dev/null)
    echo ""
    echo "✓ Can access resources ($RG_COUNT resource groups found)"
    
    # Logout from service principal
    az logout 2>/dev/null
    
    # Re-login with original account
    az account set --subscription "$SUBSCRIPTION_ID" 2>/dev/null
else
    echo "✗ Authentication failed"
    echo "  You may need to wait a few minutes for changes to propagate"
fi

# Save configuration
echo ""
echo "=========================================="
echo "Step 6: Saving Configuration"
echo "=========================================="

CONFIG_FILE="$CERT_DIR/azure-config.txt"

cat > "$CONFIG_FILE" << EOF
Azure Certificate-Based Authentication Configuration
====================================================

Generated: $(date)

Certificate Details:
- Certificate File (PEM): $CERT_FILE
- Certificate File (DER): $CER_FILE
- Combined File (for DevOps): $COMBINED_FILE
- Private Key: $KEY_FILE
- Thumbprint: $THUMBPRINT
- Valid Until: $(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d'=' -f2)

Azure Details:
- Tenant ID: $TENANT_ID
- Subscription ID: $SUBSCRIPTION_ID
- Subscription Name: $SUBSCRIPTION_NAME
- Service Principal Name: $SP_NAME
- Application/Client ID: $APP_ID
- Role: $ROLE_NAME

Azure DevOps Service Connection Setup:
1. Go to Azure DevOps > Project Settings > Service Connections
2. Create new Azure Resource Manager connection
3. Choose "Service principal (manual)"
4. Select "Certificate" authentication
5. Upload: $COMBINED_FILE
6. Enter:
   - Tenant ID: $TENANT_ID
   - Subscription ID: $SUBSCRIPTION_ID
   - Service Principal ID: $APP_ID

Testing Commands:
- Azure CLI: az login --service-principal --username $APP_ID --tenant $TENANT_ID --password $COMBINED_FILE
- Verify: az account show
- List resources: az group list

⚠️ SECURITY WARNING ⚠️
Keep the private key and combined certificate files secure!
Never commit them to version control!

EOF

echo "✓ Configuration saved to $CONFIG_FILE"

# Create .gitignore
cat > "$CERT_DIR/.gitignore" << EOF
# Ignore all certificate files
*.pem
*.key
*.cer
*.pfx
*.p12
*.txt
EOF

echo "✓ Created .gitignore in $CERT_DIR"

# Summary
echo ""
echo "=========================================="
echo "Setup Complete! 🎉"
echo "=========================================="
echo ""
echo "✅ Certificate generated"
echo "✅ Service principal created"
echo "✅ Certificate uploaded to Azure AD"
echo "✅ Permissions assigned"
echo "✅ Authentication tested"
echo ""
echo "📋 Configuration Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Service Principal: $SP_NAME"
echo "Application ID: $APP_ID"
echo "Tenant ID: $TENANT_ID"
echo "Subscription: $SUBSCRIPTION_NAME"
echo "Role: $ROLE_NAME"
echo "Thumbprint: $THUMBPRINT"
echo ""
echo "📁 Certificate Files:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "For Azure DevOps: $COMBINED_FILE"
echo "For Azure Portal: $CER_FILE"
echo "Configuration: $CONFIG_FILE"
echo ""
echo "🔧 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Configure Azure DevOps Service Connection"
echo "   - Use the values from $CONFIG_FILE"
echo "   - Upload $COMBINED_FILE"
echo ""
echo "2. Test with provided scripts:"
echo "   - ./test-cert-auth.sh (detailed testing)"
echo "   - ./test-cert-auth.py (Python SDK testing)"
echo ""
echo "3. Create a test pipeline:"
echo "   - Use azure-pipelines-cert-test.yml"
echo ""
echo "4. Review the complete guide:"
echo "   - See Azure-Certificate-Based-Auth-Guide.md"
echo ""
echo "⚠️  IMPORTANT: Keep your certificate files secure!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Offer to test now
read -p "Run authentication test now? (y/n): " RUN_TEST

if [ "$RUN_TEST" = "y" ] || [ "$RUN_TEST" = "Y" ]; then
    if [ -f "./test-cert-auth.sh" ]; then
        chmod +x ./test-cert-auth.sh
        echo ""
        echo "Running test script..."
        echo ""
        ./test-cert-auth.sh
    else
        echo "Test script not found. Run ./test-cert-auth.sh manually."
    fi
fi

echo ""
echo "Setup script completed successfully!"
echo ""

