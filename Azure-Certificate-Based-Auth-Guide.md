# Azure DevOps Certificate-Based Authentication - Complete Guide

## Overview
This guide walks you through creating OpenSSL certificates and configuring certificate-based authentication for Azure DevOps service principals.

---

## Step 1: Generate OpenSSL Certificate

### 1.1 Create a Self-Signed Certificate with Private Key

```bash
# Generate a private key and self-signed certificate (valid for 1 year)
openssl req -x509 -newkey rsa:4096 -keyout service-principal-key.pem -out service-principal-cert.pem -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=azure-devops-sp"
```

**Parameters explained:**
- `-x509`: Generate self-signed certificate
- `-newkey rsa:4096`: Create new 4096-bit RSA key
- `-keyout`: Private key output file
- `-out`: Certificate output file
- `-days 365`: Certificate validity (1 year)
- `-nodes`: Don't encrypt the private key
- `-subj`: Certificate subject (customize as needed)

### 1.2 Verify the Certificate

```bash
# View certificate details
openssl x509 -in service-principal-cert.pem -text -noout

# Check certificate dates
openssl x509 -in service-principal-cert.pem -noout -dates

# Verify certificate and key match
openssl x509 -noout -modulus -in service-principal-cert.pem | openssl md5
openssl rsa -noout -modulus -in service-principal-key.pem | openssl md5
```

### 1.3 Extract Certificate Thumbprint (Fingerprint)

```bash
# Get SHA-1 thumbprint (needed for Azure)
openssl x509 -in service-principal-cert.pem -noout -fingerprint -sha1

# Get SHA-256 thumbprint
openssl x509 -in service-principal-cert.pem -noout -fingerprint -sha256
```

### 1.4 Convert Certificate to DER Format (for Azure Upload)

```bash
# Convert PEM to DER format
openssl x509 -in service-principal-cert.pem -outform DER -out service-principal-cert.cer
```

---

## Step 2: Create/Configure Azure Service Principal

### 2.1 Create Service Principal (if not exists)

```bash
# Login to Azure
az login

# Create a new service principal
az ad sp create-for-rbac --name "azure-devops-cert-sp" --skip-assignment

# Note down the following from output:
# - appId (Application/Client ID)
# - tenant (Tenant ID)
```

### 2.2 Upload Certificate to Service Principal

**Option A: Using Azure CLI**

```bash
# Upload the certificate
az ad sp credential reset --id <APP_ID> --cert @service-principal-cert.pem --append

# Or upload the .cer file
az ad app credential reset --id <APP_ID> --cert @service-principal-cert.cer --append
```

**Option B: Using Azure Portal**

1. Go to Azure Portal (https://portal.azure.com)
2. Navigate to **Azure Active Directory** > **App registrations**
3. Find your service principal/app registration
4. Go to **Certificates & secrets**
5. Under **Certificates** tab, click **Upload certificate**
6. Upload the `service-principal-cert.cer` file
7. Add a description and click **Add**
8. Note the thumbprint shown in Azure Portal

### 2.3 Assign Required Permissions

```bash
# Assign appropriate role to the service principal
# For subscription level access:
az role assignment create --assignee <APP_ID> --role Contributor --scope /subscriptions/<SUBSCRIPTION_ID>

# For resource group level access:
az role assignment create --assignee <APP_ID> --role Contributor --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>
```

---

## Step 3: Configure Azure DevOps Service Connection

### 3.1 Manual Service Connection Setup

1. Go to your Azure DevOps project
2. Navigate to **Project Settings** (bottom left)
3. Under **Pipelines**, click **Service connections**
4. Click **New service connection**
5. Select **Azure Resource Manager**
6. Choose **Service principal (manual)**
7. Fill in the following details:
   - **Environment**: Azure Cloud
   - **Scope Level**: Subscription (or Management Group)
   - **Subscription ID**: Your Azure subscription ID
   - **Subscription Name**: Your subscription name
   - **Service Principal ID**: The `appId` from Step 2.1
   - **Authentication**: Select **Certificate**
   - **Certificate**: Upload the `service-principal-cert.pem` file (PEM format with private key)
   - **Tenant ID**: Your Azure tenant ID
   - **Service connection name**: Give it a meaningful name
8. Check **Grant access permission to all pipelines** (if needed)
9. Click **Verify and save**

### 3.2 Required Information Summary

Collect these values before configuring:
```
- Tenant ID: <your-tenant-id>
- Subscription ID: <your-subscription-id>
- Service Principal/Client ID: <app-id>
- Certificate: service-principal-cert.pem (with private key)
- Certificate Thumbprint: <from openssl fingerprint command>
```

---

## Step 4: Test Certificate-Based Authentication

### 4.1 Test with Azure CLI

```bash
# Login using service principal with certificate
az login --service-principal \
  --username <APP_ID> \
  --tenant <TENANT_ID> \
  --certificate service-principal-cert.pem

# Verify login
az account show

# List resources to test access
az resource list --output table
```

### 4.2 Test with Python Script

Create a test script `test_cert_auth.py`:

```python
#!/usr/bin/env python3
from azure.identity import CertificateCredential
from azure.mgmt.resource import ResourceManagementClient
import os

# Configuration
TENANT_ID = "<your-tenant-id>"
CLIENT_ID = "<your-app-id>"
CERTIFICATE_PATH = "./service-principal-cert.pem"
SUBSCRIPTION_ID = "<your-subscription-id>"

# Authenticate using certificate
credential = CertificateCredential(
    tenant_id=TENANT_ID,
    client_id=CLIENT_ID,
    certificate_path=CERTIFICATE_PATH
)

# Test authentication by listing resource groups
try:
    resource_client = ResourceManagementClient(credential, SUBSCRIPTION_ID)
    
    print("Authentication successful!")
    print("\nResource Groups:")
    for rg in resource_client.resource_groups.list():
        print(f"  - {rg.name} ({rg.location})")
        
except Exception as e:
    print(f"Authentication failed: {str(e)}")
```

Install required packages:
```bash
pip install azure-identity azure-mgmt-resource
```

Run the test:
```bash
python test_cert_auth.py
```

### 4.3 Test with PowerShell

```powershell
# Convert certificate for PowerShell
$certPath = "./service-principal-cert.pem"
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certPath)

# Login using certificate
Connect-AzAccount -ServicePrincipal `
    -ApplicationId "<APP_ID>" `
    -TenantId "<TENANT_ID>" `
    -CertificateThumbprint $cert.Thumbprint

# Test access
Get-AzResourceGroup
```

### 4.4 Test in Azure DevOps Pipeline

Create a test pipeline `azure-pipelines-cert-test.yml`:

```yaml
trigger: none

pool:
  vmImage: 'ubuntu-latest'

variables:
  azureServiceConnection: 'your-cert-based-service-connection-name'

stages:
- stage: TestCertAuth
  displayName: 'Test Certificate Authentication'
  jobs:
  - job: TestAzureAccess
    displayName: 'Test Azure Access'
    steps:
    - task: AzureCLI@2
      displayName: 'Test Azure CLI Access'
      inputs:
        azureSubscription: $(azureServiceConnection)
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          echo "Testing certificate-based authentication..."
          echo "Logged in as:"
          az account show
          echo ""
          echo "Resource Groups:"
          az group list --output table
          echo ""
          echo "Certificate authentication successful!"

    - task: AzurePowerShell@5
      displayName: 'Test Azure PowerShell Access'
      inputs:
        azureSubscription: $(azureServiceConnection)
        ScriptType: 'InlineScript'
        Inline: |
          Write-Host "Testing PowerShell access..."
          Get-AzContext
          Get-AzResourceGroup | Format-Table
        azurePowerShellVersion: 'LatestVersion'
```

---

## Step 5: Verification Checklist

### ✓ Certificate Verification
- [ ] Certificate is valid and not expired
- [ ] Certificate thumbprint matches in Azure AD and local cert
- [ ] Certificate includes both public and private key (for DevOps)
- [ ] Certificate is in correct format (PEM for CLI, CER for portal upload)

### ✓ Service Principal Verification
- [ ] Service principal exists in Azure AD
- [ ] Certificate is uploaded to the service principal
- [ ] Service principal has required RBAC permissions
- [ ] Tenant ID and Client ID are correct

### ✓ Azure DevOps Verification
- [ ] Service connection is created successfully
- [ ] Service connection verification passed
- [ ] Service connection has required pipeline permissions
- [ ] Test pipeline runs successfully

### ✓ Authentication Tests
- [ ] Azure CLI login works
- [ ] Can list Azure resources
- [ ] Pipeline tasks execute successfully
- [ ] No authentication errors in logs

---

## Step 6: Troubleshooting Common Issues

### Issue 1: "Certificate verification failed"
**Solution:**
```bash
# Ensure certificate and key are in correct format
openssl x509 -in service-principal-cert.pem -text -noout

# Check if certificate includes private key
grep -c "BEGIN PRIVATE KEY" service-principal-cert.pem

# If private key is separate, combine them:
cat service-principal-cert.pem service-principal-key.pem > combined-cert.pem
```

### Issue 2: "AADSTS700027: Invalid certificate"
**Solution:**
- Verify certificate is uploaded correctly to Azure AD
- Check thumbprint matches
- Ensure certificate is not expired
- Try re-uploading the certificate

### Issue 3: "Authorization failed"
**Solution:**
```bash
# Check service principal permissions
az role assignment list --assignee <APP_ID> --output table

# Add required role if missing
az role assignment create --assignee <APP_ID> --role Contributor --scope /subscriptions/<SUBSCRIPTION_ID>
```

### Issue 4: "Service connection verification failed"
**Solution:**
- Ensure you're uploading the PEM file (with private key) to Azure DevOps
- Verify Tenant ID, Subscription ID, and Client ID are correct
- Check the certificate is not password-protected
- Ensure service principal has access to the subscription

---

## Step 7: Security Best Practices

### Certificate Management
1. **Store private keys securely**: Never commit to source control
2. **Use certificate expiry monitoring**: Set reminders before expiry
3. **Rotate certificates regularly**: Update before expiry
4. **Use Azure Key Vault**: Store certificates in Key Vault for production

### Access Control
1. **Principle of least privilege**: Grant minimum required permissions
2. **Use resource group scope**: Instead of subscription-wide access
3. **Audit service principal usage**: Review Azure Activity Logs
4. **Restrict pipeline access**: Don't grant access to all pipelines

### Key Vault Integration (Recommended for Production)

```bash
# Store certificate in Key Vault
az keyvault certificate import \
  --vault-name <your-keyvault> \
  --name azure-devops-cert \
  --file service-principal-cert.pem

# Grant service principal access to Key Vault
az keyvault set-policy \
  --name <your-keyvault> \
  --spn <APP_ID> \
  --certificate-permissions get list
```

---

## Quick Reference Commands

### Generate Certificate
```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=azure-sp"
openssl x509 -in cert.pem -outform DER -out cert.cer
openssl x509 -in cert.pem -noout -fingerprint -sha1
```

### Upload to Azure
```bash
az login
az ad sp credential reset --id <APP_ID> --cert @cert.pem --append
az role assignment create --assignee <APP_ID> --role Contributor --scope /subscriptions/<SUB_ID>
```

### Test Authentication
```bash
az login --service-principal --username <APP_ID> --tenant <TENANT_ID> --certificate cert.pem
az account show
az group list
```

---

## Additional Resources

- [Azure AD Service Principal Documentation](https://learn.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)
- [Azure DevOps Service Connections](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)
- [OpenSSL Certificate Management](https://www.openssl.org/docs/man1.1.1/man1/openssl-req.html)
- [Azure RBAC Documentation](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview)

---

## Summary

You now have a complete setup for certificate-based authentication:

1. ✅ Generated OpenSSL certificates
2. ✅ Created/configured Azure service principal
3. ✅ Uploaded certificate to Azure AD
4. ✅ Configured Azure DevOps service connection
5. ✅ Tested authentication multiple ways

**Next Steps:**
- Implement certificate rotation process
- Set up monitoring and alerts
- Document your specific configuration
- Train team on certificate management

---

**Note:** Keep your private key (`service-principal-key.pem`) and combined certificate files secure. Never share them or commit them to version control.

