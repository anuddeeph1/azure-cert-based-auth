# Azure Certificate-Based Authentication Setup

This repository contains scripts and guides for setting up certificate-based authentication for Azure DevOps service principals.

## 📋 Prerequisites

Before you begin, ensure you have:

- **Azure CLI** installed ([Install guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- **OpenSSL** installed (usually pre-installed on macOS/Linux)
- **Azure subscription** with appropriate permissions
- **Azure DevOps project** where you want to set up the service connection

## 🚀 Quick Start

### 1. Generate Certificate

Run the certificate generation script:

```bash
chmod +x generate-cert.sh
./generate-cert.sh
```

This will:
- Generate a 4096-bit RSA certificate
- Create certificate files in the `./certs/` directory
- Display the certificate thumbprint
- Create files needed for both Azure Portal and Azure DevOps

**Generated Files:**
- `service-principal-key.pem` - Private key (keep secure!)
- `service-principal-cert.pem` - Certificate (PEM format)
- `service-principal-combined.pem` - Combined cert + key (for Azure DevOps)
- `service-principal-cert.cer` - Certificate (DER format, for Azure Portal)

### 2. Create Service Principal

```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac --name "azure-devops-cert-sp" --skip-assignment

# Note the appId and tenant from the output
```

### 3. Upload Certificate to Azure

**Option A: Using Azure CLI**

```bash
# Replace <APP_ID> with your application ID from step 2
az ad sp credential reset --id <APP_ID> --cert @./certs/service-principal-cert.pem --append
```

**Option B: Using Azure Portal**

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** > **App registrations**
3. Find your service principal
4. Go to **Certificates & secrets** > **Certificates** tab
5. Click **Upload certificate**
6. Upload `./certs/service-principal-cert.cer`

### 4. Assign Permissions

```bash
# Get your subscription ID
az account show --query id -o tsv

# Assign Contributor role (replace placeholders)
az role assignment create \
  --assignee <APP_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

### 5. Test Authentication

**Option A: Using Bash Script**

```bash
chmod +x test-cert-auth.sh
./test-cert-auth.sh
```

**Option B: Using Python Script**

```bash
# Install required packages
pip install azure-identity azure-mgmt-resource

# Run test
chmod +x test-cert-auth.py
python test-cert-auth.py
```

### 6. Configure Azure DevOps

1. Go to your Azure DevOps project
2. Navigate to **Project Settings** > **Service connections**
3. Click **New service connection**
4. Select **Azure Resource Manager**
5. Choose **Service principal (manual)**
6. Select **Certificate** authentication
7. Upload `./certs/service-principal-combined.pem`
8. Fill in:
   - **Tenant ID**: From step 2
   - **Subscription ID**: Your subscription ID
   - **Service Principal ID**: The appId from step 2
9. Click **Verify and save**

### 7. Test in Pipeline

Create a pipeline using `azure-pipelines-cert-test.yml`:

```bash
# Commit the test pipeline
git add azure-pipelines-cert-test.yml
git commit -m "Add certificate auth test pipeline"
git push

# Then create a pipeline in Azure DevOps pointing to this file
```

## 📁 Files in This Repository

| File | Description |
|------|-------------|
| `Azure-Certificate-Based-Auth-Guide.md` | Comprehensive guide with all steps |
| `generate-cert.sh` | Script to generate OpenSSL certificates |
| `test-cert-auth.sh` | Bash script to test authentication |
| `test-cert-auth.py` | Python script to test authentication |
| `azure-pipelines-cert-test.yml` | Azure Pipeline to test the service connection |
| `README.md` | This file |

## 🔒 Security Best Practices

1. **Never commit certificates to Git**
   - The `./certs/` directory is git-ignored by default
   - Keep private keys secure

2. **Rotate certificates regularly**
   - Certificates expire after 1 year (default)
   - Set reminders to rotate before expiry

3. **Use least privilege**
   - Only grant necessary permissions to service principal
   - Use resource group scope instead of subscription-wide

4. **Monitor usage**
   - Review Azure Activity Logs regularly
   - Set up alerts for suspicious activity

5. **Use Azure Key Vault in production**
   - Store certificates in Key Vault
   - Use managed identities where possible

## 🧪 Testing Commands

### Manual Testing with Azure CLI

```bash
# Login with certificate
az login --service-principal \
  --username <CLIENT_ID> \
  --tenant <TENANT_ID> \
  --certificate ./certs/service-principal-combined.pem

# Verify login
az account show

# List resources
az group list
az resource list

# Check permissions
az role assignment list --assignee <CLIENT_ID>
```

### Testing with Python

```python
from azure.identity import CertificateCredential
from azure.mgmt.resource import ResourceManagementClient

credential = CertificateCredential(
    tenant_id="<TENANT_ID>",
    client_id="<CLIENT_ID>",
    certificate_path="./certs/service-principal-combined.pem"
)

client = ResourceManagementClient(credential, "<SUBSCRIPTION_ID>")
for rg in client.resource_groups.list():
    print(rg.name)
```

## 🔧 Troubleshooting

### Error: "Certificate verification failed"

**Solution:**
- Ensure certificate is valid: `openssl x509 -in cert.pem -noout -checkend 0`
- Verify certificate includes private key
- Check thumbprint matches in Azure Portal

### Error: "AADSTS700027: Invalid certificate"

**Solution:**
- Re-upload certificate to Azure AD
- Verify you're using the correct certificate file
- Check certificate is not expired

### Error: "Authorization failed"

**Solution:**
```bash
# Check service principal permissions
az role assignment list --assignee <CLIENT_ID> --output table

# Add required role
az role assignment create \
  --assignee <CLIENT_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

### Error: "Service connection verification failed"

**Solution:**
- Use the **combined** PEM file (cert + key) for Azure DevOps
- Verify Tenant ID, Subscription ID, and Client ID are correct
- Ensure service principal has access to the subscription

## 📚 Additional Resources

- [Azure DevOps Documentation](https://learn.microsoft.com/en-us/azure/devops/)
- [Azure Service Principals](https://learn.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/)

## 📝 Quick Reference

### Get Certificate Information

```bash
# View certificate details
openssl x509 -in cert.pem -text -noout

# Get thumbprint
openssl x509 -in cert.pem -noout -fingerprint -sha1

# Check expiry
openssl x509 -in cert.pem -noout -dates

# Verify certificate
openssl verify cert.pem
```

### Required Information for Azure DevOps

When configuring the service connection, you need:
- ✅ Tenant ID
- ✅ Subscription ID  
- ✅ Client/Application ID (Service Principal ID)
- ✅ Certificate file (PEM format with private key)

## 🆘 Need Help?

1. Check the comprehensive guide: `Azure-Certificate-Based-Auth-Guide.md`
2. Run the test scripts to identify issues
3. Review Azure Activity Logs in Azure Portal
4. Check service principal permissions with `az role assignment list`

## 🎯 Next Steps After Setup

Once authentication is working:

1. ✅ Implement certificate rotation process
2. ✅ Move certificates to Azure Key Vault
3. ✅ Set up monitoring and alerts
4. ✅ Document your specific configuration
5. ✅ Train team members on certificate management

---

**⚠️ Security Warning:** Keep your private key files secure. Never commit them to version control or share them publicly.

