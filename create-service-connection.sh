#!/bin/bash

# Create Azure DevOps Service Connection for Certificate Authentication
# This script creates the service connection via Azure DevOps REST API

set -e

echo "=========================================="
echo "Azure DevOps Service Connection Creator"
echo "=========================================="
echo ""

# Configuration from your setup
TENANT_ID="3d95acd6-b6ee-428e-a7a0-196120fc3c65"
SUBSCRIPTION_ID="baf89069-e8f3-46f8-b74e-c146931ce7a4"
SUBSCRIPTION_NAME="Microsoft Azure Sponsorship"
SERVICE_PRINCIPAL_ID="042aea62-c886-46a1-b2f8-25c9af22a2db"
CERT_FILE="./certs/service-principal-combined.pem"

# User inputs needed
echo "Please provide the following Azure DevOps details:"
echo ""
read -p "Azure DevOps Organization Name (e.g., 'myorg' from dev.azure.com/myorg): " ADO_ORG
read -p "Azure DevOps Project Name: " ADO_PROJECT
read -p "Service Connection Name [default: azure-cert-sp-connection]: " SERVICE_CONNECTION_NAME
SERVICE_CONNECTION_NAME=${SERVICE_CONNECTION_NAME:-azure-cert-sp-connection}

echo ""
echo "=========================================="
echo "Configuration Summary"
echo "=========================================="
echo "Organization:     $ADO_ORG"
echo "Project:          $ADO_PROJECT"
echo "Connection Name:  $SERVICE_CONNECTION_NAME"
echo "Subscription:     $SUBSCRIPTION_NAME"
echo "Service Principal: $SERVICE_PRINCIPAL_ID"
echo ""

read -p "Continue with this configuration? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "=========================================="
echo "Step 1: Encode Certificate"
echo "=========================================="

# Read certificate and encode to base64 (single line, no line breaks)
CERT_BASE64=$(cat "$CERT_FILE" | base64 | tr -d '\n')
echo "✓ Certificate encoded"

echo ""
echo "=========================================="
echo "Step 2: Get Azure DevOps PAT Token"
echo "=========================================="
echo ""
echo "You need a Personal Access Token (PAT) with 'Service Connections' permissions."
echo ""
echo "To create one:"
echo "1. Go to: https://dev.azure.com/$ADO_ORG/_usersSettings/tokens"
echo "2. Click 'New Token'"
echo "3. Name: 'Service Connection Creator'"
echo "4. Scopes: Select 'Service Connections' → Read, query, & manage"
echo "5. Click 'Create' and copy the token"
echo ""
read -s -p "Enter your Azure DevOps PAT Token: " ADO_PAT
echo ""
echo "✓ Token received"

echo ""
echo "=========================================="
echo "Step 3: Create Service Connection"
echo "=========================================="

# Create the service connection JSON
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

# Create the service connection
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n :$ADO_PAT | base64)" \
  -d "$SERVICE_CONNECTION_JSON" \
  "$API_URL")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo "✓ Service connection created successfully!"
    echo ""
    
    # Extract service connection ID
    CONNECTION_ID=$(echo "$RESPONSE_BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    echo "=========================================="
    echo "Success!"
    echo "=========================================="
    echo "Service Connection Name: $SERVICE_CONNECTION_NAME"
    echo "Service Connection ID:   $CONNECTION_ID"
    echo ""
    echo "You can view it at:"
    echo "https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_settings/adminservices"
    echo ""
else
    echo "✗ Failed to create service connection"
    echo "HTTP Status Code: $HTTP_CODE"
    echo "Response:"
    echo "$RESPONSE_BODY" | jq . 2>/dev/null || echo "$RESPONSE_BODY"
    exit 1
fi

echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo "1. Verify the connection in Azure DevOps UI"
echo "2. Grant pipeline permissions if needed"
echo "3. Test with a simple pipeline"
echo ""

