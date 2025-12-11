#!/bin/bash

# Test Azure Certificate-Based Authentication
# This script tests if your certificate authentication is working correctly

set -e

echo "======================================"
echo "Azure Certificate Auth Test Script"
echo "======================================"
echo ""

# Check if required tools are installed
command -v az >/dev/null 2>&1 || { echo "✗ Azure CLI is not installed. Please install it first."; exit 1; }
echo "✓ Azure CLI is installed"

# Configuration
CERT_FILE="./certs/service-principal-combined.pem"

# Check if certificate exists
if [ ! -f "$CERT_FILE" ]; then
    CERT_FILE="./certs/service-principal-cert.pem"
    if [ ! -f "$CERT_FILE" ]; then
        echo "✗ Certificate file not found!"
        echo "  Expected: ./certs/service-principal-combined.pem or ./certs/service-principal-cert.pem"
        echo "  Run ./generate-cert.sh first to generate certificates"
        exit 1
    fi
fi
echo "✓ Certificate file found: $CERT_FILE"

echo ""
echo "Please provide the following information:"
echo ""

# Get Azure details from user
read -p "Enter Tenant ID: " TENANT_ID
if [ -z "$TENANT_ID" ]; then
    echo "✗ Tenant ID is required"
    exit 1
fi

read -p "Enter Application/Client ID (Service Principal ID): " CLIENT_ID
if [ -z "$CLIENT_ID" ]; then
    echo "✗ Client ID is required"
    exit 1
fi

read -p "Enter Subscription ID (optional, press Enter to skip): " SUBSCRIPTION_ID

echo ""
echo "======================================"
echo "Test 1: Certificate Validation"
echo "======================================"

# Validate certificate
echo "Checking certificate validity..."
openssl x509 -in "$CERT_FILE" -noout -checkend 0
if [ $? -eq 0 ]; then
    echo "✓ Certificate is valid and not expired"
    
    # Show expiry date
    EXPIRY=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d'=' -f2)
    echo "  Expires: $EXPIRY"
else
    echo "✗ Certificate has expired or is invalid"
    exit 1
fi

# Show thumbprint
echo ""
echo "Certificate Thumbprint:"
THUMBPRINT=$(openssl x509 -in "$CERT_FILE" -noout -fingerprint -sha1 | cut -d'=' -f2)
echo "  SHA-1: $THUMBPRINT"
echo "  (Verify this matches in Azure Portal)"

echo ""
echo "======================================"
echo "Test 2: Azure Authentication"
echo "======================================"

# Try to login using certificate
echo "Attempting to login with certificate..."
az login --service-principal \
    --username "$CLIENT_ID" \
    --tenant "$TENANT_ID" \
    --certificate "$CERT_FILE" \
    --allow-no-subscriptions

if [ $? -eq 0 ]; then
    echo "✓ Authentication successful!"
else
    echo "✗ Authentication failed!"
    echo ""
    echo "Possible issues:"
    echo "  1. Certificate not uploaded to Azure AD"
    echo "  2. Incorrect Client ID or Tenant ID"
    echo "  3. Certificate expired or invalid"
    echo "  4. Service principal doesn't exist"
    exit 1
fi

echo ""
echo "======================================"
echo "Test 3: Account Information"
echo "======================================"

# Show account details
echo "Current account details:"
az account show --output table

echo ""
echo "======================================"
echo "Test 4: Subscription Access"
echo "======================================"

# If subscription ID was provided, try to set it
if [ ! -z "$SUBSCRIPTION_ID" ]; then
    echo "Setting subscription: $SUBSCRIPTION_ID"
    az account set --subscription "$SUBSCRIPTION_ID"
    
    if [ $? -eq 0 ]; then
        echo "✓ Subscription set successfully"
    else
        echo "✗ Failed to set subscription"
        echo "  The service principal may not have access to this subscription"
    fi
fi

echo ""
echo "Available subscriptions:"
az account list --output table

echo ""
echo "======================================"
echo "Test 5: Resource Access"
echo "======================================"

# Try to list resource groups
echo "Testing resource group access..."
az group list --output table 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Can list resource groups"
else
    echo "✗ Cannot list resource groups"
    echo "  The service principal may not have Reader/Contributor permissions"
fi

echo ""
echo "======================================"
echo "Test 6: RBAC Permissions"
echo "======================================"

# Check role assignments
echo "Checking service principal role assignments..."
az role assignment list --assignee "$CLIENT_ID" --output table

echo ""
echo "======================================"
echo "Test Summary"
echo "======================================"
echo "✓ Certificate is valid"
echo "✓ Authentication successful"
echo "✓ Can access Azure API"
echo ""
echo "Configuration Details:"
echo "  Tenant ID:     $TENANT_ID"
echo "  Client ID:     $CLIENT_ID"
echo "  Certificate:   $CERT_FILE"
echo "  Thumbprint:    $THUMBPRINT"
echo ""
echo "======================================"
echo "Next Steps for Azure DevOps"
echo "======================================"
echo "1. Go to Azure DevOps Project Settings"
echo "2. Navigate to Pipelines > Service connections"
echo "3. Create new Azure Resource Manager connection"
echo "4. Select 'Service principal (manual)'"
echo "5. Choose 'Certificate' authentication"
echo "6. Upload: $CERT_FILE"
echo "7. Use the following values:"
echo "   - Tenant ID: $TENANT_ID"
echo "   - Client ID: $CLIENT_ID"
echo "   - Subscription ID: $SUBSCRIPTION_ID"
echo ""
echo "======================================"
echo "Test complete!"
echo "======================================"

# Logout
echo ""
read -p "Logout from Azure CLI? (y/n) [default: y]: " LOGOUT
LOGOUT=${LOGOUT:-y}

if [ "$LOGOUT" = "y" ] || [ "$LOGOUT" = "Y" ]; then
    az logout
    echo "✓ Logged out"
fi

