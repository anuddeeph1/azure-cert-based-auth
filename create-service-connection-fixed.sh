#!/bin/bash

# Create Azure DevOps Service Connection for Certificate Authentication
# Fixed version - gets project ID automatically

set -e

echo "=========================================="
echo "Azure DevOps Service Connection Creator"
echo "For Organization: nirmata / Project: anudeep"
echo "=========================================="
echo ""

# Your Azure configuration
TENANT_ID="3d95acd6-b6ee-428e-a7a0-196120fc3c65"
SUBSCRIPTION_ID="baf89069-e8f3-46f8-b74e-c146931ce7a4"
SUBSCRIPTION_NAME="Microsoft Azure Sponsorship"
SERVICE_PRINCIPAL_ID="042aea62-c886-46a1-b2f8-25c9af22a2db"
CERT_FILE="./certs/service-principal-combined.pem"

# Your Azure DevOps configuration
ADO_ORG="nirmata"
ADO_PROJECT="anudeep"

echo "Configuration:"
echo "  Organization:     $ADO_ORG"
echo "  Project:          $ADO_PROJECT"
echo "  Subscription:     $SUBSCRIPTION_NAME"
echo "  Service Principal: $SERVICE_PRINCIPAL_ID"
echo ""

# Service connection name
read -p "Service Connection Name [default: azure-cert-sp-connection]: " SERVICE_CONNECTION_NAME
SERVICE_CONNECTION_NAME=${SERVICE_CONNECTION_NAME:-azure-cert-sp-connection}

echo ""
echo "Creating service connection: $SERVICE_CONNECTION_NAME"
echo ""

# Check certificate file exists
if [ ! -f "$CERT_FILE" ]; then
    echo "✗ Error: Certificate file not found: $CERT_FILE"
    exit 1
fi

echo "=========================================="
echo "Step 1: Get Azure DevOps PAT Token"
echo "=========================================="
echo ""
read -s -p "Enter your Azure DevOps PAT Token: " ADO_PAT
echo ""

if [ -z "$ADO_PAT" ]; then
    echo "✗ Error: PAT token is required"
    exit 1
fi

echo "✓ Token received"

echo ""
echo "=========================================="
echo "Step 2: Get Project ID"
echo "=========================================="

# Get project details to retrieve the project GUID
PROJECT_API_URL="https://dev.azure.com/$ADO_ORG/_apis/projects/$ADO_PROJECT?api-version=7.1"

PROJECT_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Basic $(echo -n :$ADO_PAT | base64)" \
  "$PROJECT_API_URL")

PROJECT_BODY=$(echo "$PROJECT_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
PROJECT_STATUS=$(echo "$PROJECT_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$PROJECT_STATUS" != "200" ]; then
    echo "✗ Error: Failed to get project details (HTTP $PROJECT_STATUS)"
    echo "Response: $PROJECT_BODY"
    exit 1
fi

# Extract project ID
PROJECT_ID=$(echo "$PROJECT_BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$PROJECT_ID" ]; then
    echo "✗ Error: Could not extract project ID"
    echo "Response: $PROJECT_BODY"
    exit 1
fi

echo "✓ Project ID retrieved: $PROJECT_ID"

echo ""
echo "=========================================="
echo "Step 3: Encode Certificate"
echo "=========================================="

# Read certificate and encode to base64 (single line, no line breaks)
CERT_BASE64=$(cat "$CERT_FILE" | base64 | tr -d '\n')
echo "✓ Certificate encoded (${#CERT_BASE64} characters)"

echo ""
echo "=========================================="
echo "Step 4: Create Service Connection"
echo "=========================================="

# Create the service connection JSON with project ID
SERVICE_CONNECTION_JSON=$(cat <<EOF
{
  "data": {
    "subscriptionId": "$SUBSCRIPTION_ID",
    "subscriptionName": "$SUBSCRIPTION_NAME",
    "environment": "AzureCloud",
    "scopeLevel": "Subscription",
    "creationMode": "Manual"
  },
  "name": "$SERVICE_CONNECTION_NAME",
  "type": "AzureRM",
  "url": "https://management.azure.com/",
  "authorization": {
    "parameters": {
      "tenantid": "$TENANT_ID",
      "serviceprincipalid": "$SERVICE_PRINCIPAL_ID",
      "authenticationType": "spnCertificate",
      "servicePrincipalCertificate": "$CERT_BASE64"
    },
    "scheme": "ServicePrincipal"
  },
  "isShared": false,
  "isReady": true,
  "serviceEndpointProjectReferences": [
    {
      "projectReference": {
        "id": "$PROJECT_ID",
        "name": "$ADO_PROJECT"
      },
      "name": "$SERVICE_CONNECTION_NAME"
    }
  ]
}
EOF
)

# Azure DevOps REST API endpoint
API_URL="https://dev.azure.com/$ADO_ORG/_apis/serviceendpoint/endpoints?api-version=7.1-preview.4"

echo "Calling Azure DevOps API..."

# Create the service connection
HTTP_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n :$ADO_PAT | base64)" \
  -d "$SERVICE_CONNECTION_JSON" \
  "$API_URL")

# Extract HTTP status and body
HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

echo ""

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
    echo "=========================================="
    echo "✅ SUCCESS!"
    echo "=========================================="
    echo ""
    
    # Try to extract service connection ID
    CONNECTION_ID=$(echo "$HTTP_BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "N/A")
    
    echo "Service Connection Created:"
    echo "  Name:       $SERVICE_CONNECTION_NAME"
    echo "  ID:         $CONNECTION_ID"
    echo "  Project:    $ADO_PROJECT ($PROJECT_ID)"
    echo ""
    echo "View it at:"
    echo "  https://dev.azure.com/nirmata/anudeep/_settings/adminservices"
    echo ""
    echo "=========================================="
    echo "Next Steps:"
    echo "=========================================="
    echo "1. ✓ Service connection is created"
    echo "2. Go to Azure DevOps and verify it appears"
    echo "3. Grant pipeline permissions (if needed)"
    echo "4. Test with a simple pipeline"
    echo ""
    echo "Test Pipeline YAML:"
    echo "-------------------"
    cat <<'YAML'
trigger: none
pool:
  vmImage: 'ubuntu-latest'
steps:
- task: AzureCLI@2
  displayName: 'Test Certificate Auth'
  inputs:
    azureSubscription: 'azure-cert-sp-connection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      echo "Testing certificate authentication..."
      az account show
      echo ""
      az group list --output table
      echo ""
      echo "✅ Certificate authentication successful!"
YAML
    echo ""
    echo "=========================================="
    echo "🎉 Setup Complete! 🎉"
    echo "=========================================="
else
    echo "=========================================="
    echo "✗ FAILED"
    echo "=========================================="
    echo "HTTP Status Code: $HTTP_STATUS"
    echo ""
    echo "Response:"
    echo "$HTTP_BODY" | python3 -m json.tool 2>/dev/null || echo "$HTTP_BODY"
    echo ""
    echo "Common Issues:"
    echo "1. Certificate authentication type may not be supported via API"
    echo "   → Try creating via UI with 'Secret' instead"
    echo "2. PAT token needs additional permissions"
    echo "   → Verify 'Full access' or 'Service Connections' permission"
    echo "3. Azure DevOps API version may have changed"
    echo "   → Contact Azure DevOps support"
    echo ""
    exit 1
fi

