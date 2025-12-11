#!/bin/bash

# Fix Azure DevOps Service Connection - Certificate Format Issue
# Deletes and recreates with proper certificate handling

set -e

echo "=========================================="
echo "Fix Service Connection Certificate"
echo "=========================================="
echo ""

# Configuration
ADO_ORG="nirmata"
ADO_PROJECT="anudeep"
SERVICE_CONNECTION_ID="dbdb8ebb-380c-4cfb-aada-b1a9c6d85587"
SERVICE_CONNECTION_NAME="azure-cert-sp-connection"
CERT_FILE="./certs/service-principal-combined.pem"

echo "This script will:"
echo "1. Delete the existing service connection"
echo "2. Recreate it with properly formatted certificate"
echo ""

read -p "Continue? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Cancelled"
    exit 0
fi

echo ""
read -s -p "Enter your Azure DevOps PAT Token: " ADO_PAT
echo ""

if [ -z "$ADO_PAT" ]; then
    echo "✗ Error: PAT token is required"
    exit 1
fi

echo ""
echo "=========================================="
echo "Step 1: Delete Existing Connection"
echo "=========================================="

DELETE_URL="https://dev.azure.com/$ADO_ORG/_apis/serviceendpoint/endpoints/$SERVICE_CONNECTION_ID?api-version=7.1-preview.4"

DELETE_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X DELETE \
  -H "Authorization: Basic $(echo -n :$ADO_PAT | base64)" \
  "$DELETE_URL")

DELETE_STATUS=$(echo "$DELETE_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$DELETE_STATUS" = "204" ] || [ "$DELETE_STATUS" = "200" ]; then
    echo "✓ Service connection deleted"
else
    echo "⚠ Delete returned status: $DELETE_STATUS (might already be deleted)"
fi

sleep 2

echo ""
echo "=========================================="
echo "Step 2: Get Project ID"
echo "=========================================="

PROJECT_API_URL="https://dev.azure.com/$ADO_ORG/_apis/projects/$ADO_PROJECT?api-version=7.1"

PROJECT_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Basic $(echo -n :$ADO_PAT | base64)" \
  "$PROJECT_API_URL")

PROJECT_BODY=$(echo "$PROJECT_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
PROJECT_STATUS=$(echo "$PROJECT_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

if [ "$PROJECT_STATUS" != "200" ]; then
    echo "✗ Error: Failed to get project details"
    exit 1
fi

PROJECT_ID=$(echo "$PROJECT_BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "✓ Project ID: $PROJECT_ID"

echo ""
echo "=========================================="
echo "Step 3: Prepare Certificate (No Base64)"
echo "=========================================="

# Read certificate content directly (no base64 encoding)
# Azure DevOps API should handle PEM format directly
CERT_CONTENT=$(cat "$CERT_FILE")
echo "✓ Certificate loaded (${#CERT_CONTENT} characters)"

# Create JSON with certificate as-is
# We'll use jq to properly escape it
if ! command -v jq &> /dev/null; then
    echo "⚠ jq not found, installing..."
    brew install jq || (echo "✗ Failed to install jq. Please install manually: brew install jq" && exit 1)
fi

echo ""
echo "=========================================="
echo "Step 4: Create Service Connection"
echo "=========================================="

# Your Azure configuration
TENANT_ID="3d95acd6-b6ee-428e-a7a0-196120fc3c65"
SUBSCRIPTION_ID="baf89069-e8f3-46f8-b74e-c146931ce7a4"
SUBSCRIPTION_NAME="Microsoft Azure Sponsorship"
SERVICE_PRINCIPAL_ID="042aea62-c886-46a1-b2f8-25c9af22a2db"

# Create JSON using jq for proper escaping
SERVICE_CONNECTION_JSON=$(jq -n \
  --arg tenantId "$TENANT_ID" \
  --arg subId "$SUBSCRIPTION_ID" \
  --arg subName "$SUBSCRIPTION_NAME" \
  --arg spId "$SERVICE_PRINCIPAL_ID" \
  --arg connName "$SERVICE_CONNECTION_NAME" \
  --arg projId "$PROJECT_ID" \
  --arg projName "$ADO_PROJECT" \
  --arg cert "$CERT_CONTENT" \
  '{
    "data": {
      "subscriptionId": $subId,
      "subscriptionName": $subName,
      "environment": "AzureCloud",
      "scopeLevel": "Subscription",
      "creationMode": "Manual"
    },
    "name": $connName,
    "type": "AzureRM",
    "url": "https://management.azure.com/",
    "authorization": {
      "parameters": {
        "tenantid": $tenantId,
        "serviceprincipalid": $spId,
        "authenticationType": "spnCertificate",
        "servicePrincipalCertificate": $cert
      },
      "scheme": "ServicePrincipal"
    },
    "isShared": false,
    "isReady": true,
    "serviceEndpointProjectReferences": [
      {
        "projectReference": {
          "id": $projId,
          "name": $projName
        },
        "name": $connName
      }
    ]
  }')

API_URL="https://dev.azure.com/$ADO_ORG/_apis/serviceendpoint/endpoints?api-version=7.1-preview.4"

echo "Creating service connection..."

HTTP_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n :$ADO_PAT | base64)" \
  -d "$SERVICE_CONNECTION_JSON" \
  "$API_URL")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed -e 's/HTTP_STATUS\:.*//g')
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tr -d '\n' | sed -e 's/.*HTTP_STATUS://')

echo ""

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
    echo "=========================================="
    echo "✅ SUCCESS!"
    echo "=========================================="
    echo ""
    
    CONNECTION_ID=$(echo "$HTTP_BODY" | jq -r '.id' 2>/dev/null || echo "N/A")
    
    echo "Service Connection Recreated:"
    echo "  Name:    $SERVICE_CONNECTION_NAME"
    echo "  ID:      $CONNECTION_ID"
    echo ""
    echo "Test it again in Azure DevOps:"
    echo "  https://dev.azure.com/nirmata/anudeep/_build"
    echo ""
else
    echo "=========================================="
    echo "✗ FAILED"
    echo "=========================================="
    echo "HTTP Status: $HTTP_STATUS"
    echo ""
    echo "Response:"
    echo "$HTTP_BODY" | jq . 2>/dev/null || echo "$HTTP_BODY"
    echo ""
    exit 1
fi

