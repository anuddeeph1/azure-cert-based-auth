# Manual Service Connection Setup - Alternative Methods

Since the Azure DevOps UI doesn't show the Certificate option, here are alternative ways to create the service connection.

---

## Method 1: Using the Provided Script (Easiest)

### Step 1: Create Azure DevOps PAT Token

1. Go to: `https://dev.azure.com/{your-organization}/_usersSettings/tokens`
2. Click **"New Token"**
3. Configure:
   - **Name:** Service Connection Creator
   - **Organization:** Your organization
   - **Expiration:** 30 days (or custom)
   - **Scopes:** Select "Show all scopes" → Find "Service Connections" → Check "Read, query, & manage"
4. Click **"Create"**
5. **Copy the token** (you won't see it again!)

### Step 2: Run the Script

```bash
cd /Users/anudeepnalla/Downloads/novartis/azure-cert/novartis-azure-devops
./create-service-connection.sh
```

### Step 3: Provide Information

The script will ask for:
- Azure DevOps Organization name
- Project name
- Service connection name (or use default)
- Your PAT token

### Step 4: Verify

After successful creation, go to:
```
https://dev.azure.com/{your-org}/{your-project}/_settings/adminservices
```

You should see your new service connection!

---

## Method 2: Using Azure DevOps CLI Extension

### Step 1: Install Azure DevOps Extension

```bash
az extension add --name azure-devops
```

### Step 2: Login to Azure DevOps

```bash
az devops login
```

(Enter your PAT token when prompted)

### Step 3: Create Service Endpoint

```bash
# Set defaults
az devops configure --defaults organization=https://dev.azure.com/{YOUR_ORG} project={YOUR_PROJECT}

# Prepare certificate
CERT_BASE64=$(cat certs/service-principal-combined.pem | base64 | tr -d '\n')

# Create endpoint (you'll need to use REST API as CLI doesn't support cert directly)
# See Method 1 (script) for the full implementation
```

---

## Method 3: Using Azure DevOps REST API Directly

### Prerequisites

You need:
- Azure DevOps PAT token with "Service Connections" permissions
- Your certificate file: `certs/service-principal-combined.pem`

### Step-by-Step

#### 1. Encode Certificate

```bash
cd /Users/anudeepnalla/Downloads/novartis/azure-cert/novartis-azure-devops

# Encode certificate to base64 (single line, no breaks)
CERT_BASE64=$(cat certs/service-principal-combined.pem | base64 | tr -d '\n')

echo "Certificate encoded. Length: ${#CERT_BASE64} characters"
```

#### 2. Create JSON Payload

Create a file `service-connection.json`:

```json
{
  "data": {
    "subscriptionId": "baf89069-e8f3-46f8-b74e-c146931ce7a4",
    "subscriptionName": "Microsoft Azure Sponsorship",
    "environment": "AzureCloud",
    "scopeLevel": "Subscription",
    "creationMode": "Manual"
  },
  "name": "azure-cert-sp-connection",
  "type": "AzureRM",
  "url": "https://management.azure.com/",
  "authorization": {
    "parameters": {
      "tenantid": "3d95acd6-b6ee-428e-a7a0-196120fc3c65",
      "serviceprincipalid": "042aea62-c886-46a1-b2f8-25c9af22a2db",
      "authenticationType": "spnCertificate",
      "servicePrincipalCertificate": "PASTE_BASE64_CERTIFICATE_HERE"
    },
    "scheme": "ServicePrincipal"
  },
  "isShared": false,
  "isReady": true,
  "serviceEndpointProjectReferences": [
    {
      "projectReference": {
        "name": "YOUR_PROJECT_NAME"
      },
      "name": "azure-cert-sp-connection"
    }
  ]
}
```

**Replace:**
- `PASTE_BASE64_CERTIFICATE_HERE` with the base64 encoded certificate
- `YOUR_PROJECT_NAME` with your actual project name

#### 3. Make API Call

```bash
# Set variables
ADO_ORG="your-organization"
ADO_PAT="your-pat-token"

# Create service connection
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n :$ADO_PAT | base64)" \
  -d @service-connection.json \
  "https://dev.azure.com/$ADO_ORG/_apis/serviceendpoint/endpoints?api-version=7.1-preview.4"
```

#### 4. Verify Response

Successful response will return HTTP 200/201 with the created service connection details.

---

## Method 4: Use Workload Identity Federation (Modern Alternative)

If certificate authentication continues to be problematic in the UI, you can use Workload Identity Federation (the "Recommended" option you saw).

### Pros:
- ✅ No certificates to manage
- ✅ More secure (no secrets/certs stored)
- ✅ Fully supported in Azure DevOps UI

### Cons:
- ❌ Requires different Azure setup
- ❌ Your current certificate setup won't be used

**Would you like guidance on setting up Workload Identity Federation instead?**

---

## Troubleshooting

### Script Fails with "jq: command not found"

Install jq:
```bash
brew install jq
```

### API Returns 401 Unauthorized

- Check your PAT token has correct permissions
- Verify PAT hasn't expired
- Make sure you're using the correct organization name

### API Returns 400 Bad Request

- Verify all IDs are correct
- Check certificate base64 encoding has no line breaks
- Ensure project name is exact

### Connection Created but Shows Error

- Wait 2-3 minutes for Azure AD propagation
- Verify service principal permissions in Azure
- Check certificate hasn't expired

---

## Quick Reference

### Your Values

```
Tenant ID:          3d95acd6-b6ee-428e-a7a0-196120fc3c65
Subscription ID:    baf89069-e8f3-46f8-b74e-c146931ce7a4
Subscription Name:  Microsoft Azure Sponsorship
Service Principal:  042aea62-c886-46a1-b2f8-25c9af22a2db
Certificate File:   certs/service-principal-combined.pem
```

### Azure DevOps API Endpoint

```
https://dev.azure.com/{organization}/_apis/serviceendpoint/endpoints?api-version=7.1-preview.4
```

### Test the Connection

After creation, test with this pipeline:

```yaml
trigger: none

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: 'azure-cert-sp-connection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az account show
      az group list --output table
```

---

## Recommended Approach

**Use Method 1 (the script)** - it's the easiest and handles all the complexity for you!

```bash
./create-service-connection.sh
```

Just have your PAT token ready and the script will do the rest!

---

## Need Help?

- **Script issues:** Check you have `curl` and `base64` commands available
- **API issues:** Verify your PAT token permissions
- **Authentication issues:** Run `./test-cert-auth.sh` to verify Azure setup

All your Azure setup is correct - we just need to create the DevOps connection via API instead of UI!

