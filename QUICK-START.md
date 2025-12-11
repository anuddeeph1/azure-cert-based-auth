# 🚀 Quick Start Guide - Azure Certificate Authentication

## 30-Second Overview

This setup allows you to authenticate Azure DevOps pipelines using certificates instead of client secrets, providing better security and easier management.

---

## ⚡ Super Quick Setup (5 minutes)

### Option 1: Automated Setup (Recommended)

```bash
# Run the complete setup script
./setup-azure-cert-auth.sh
```

This script will:
1. ✅ Generate certificates
2. ✅ Create service principal
3. ✅ Upload certificate to Azure
4. ✅ Assign permissions
5. ✅ Test authentication

### Option 2: Manual Setup

```bash
# Step 1: Generate certificate
./generate-cert.sh

# Step 2: Create service principal and upload cert
az login
az ad sp create-for-rbac --name "azure-devops-cert-sp" --skip-assignment
# Note the appId from output

# Step 3: Upload certificate (replace <APP_ID>)
az ad sp credential reset --id <APP_ID> --cert @./certs/service-principal-cert.pem --append

# Step 4: Assign permissions (replace <APP_ID> and <SUBSCRIPTION_ID>)
az role assignment create --assignee <APP_ID> --role Contributor --scope /subscriptions/<SUBSCRIPTION_ID>

# Step 5: Test
./test-cert-auth.sh
```

---

## 🎯 Configure Azure DevOps (2 minutes)

After running setup:

1. **Go to Azure DevOps**
   - Your Project → Settings → Service Connections

2. **Create New Connection**
   - Click "New service connection"
   - Select "Azure Resource Manager"
   - Choose "Service principal (manual)"

3. **Fill in Details**
   ```
   Tenant ID: [from setup output]
   Subscription ID: [from setup output]
   Service Principal ID: [from setup output]
   Authentication: Certificate
   Certificate: Upload ./certs/service-principal-combined.pem
   ```

4. **Verify & Save**
   - Click "Verify and save"
   - Should show ✅ "Verification Succeeded"

---

## 🧪 Test Your Setup

### Test 1: Command Line
```bash
./test-cert-auth.sh
```

### Test 2: Python
```bash
pip install azure-identity azure-mgmt-resource
./test-cert-auth.py
```

### Test 3: Azure Pipeline
1. Create pipeline in Azure DevOps
2. Point to `azure-pipelines-cert-test.yml`
3. Update service connection name in the file
4. Run pipeline

---

## 📋 What You Get

After setup, you'll have:

```
certs/
├── service-principal-key.pem          ← Private key (keep secure!)
├── service-principal-cert.pem         ← Certificate (PEM format)
├── service-principal-combined.pem     ← For Azure DevOps ⭐
├── service-principal-cert.cer         ← For Azure Portal
└── azure-config.txt                   ← Your configuration details
```

---

## 🔑 Key Information You Need

After running the setup, you'll need these values:

| Field | Where to Find |
|-------|---------------|
| **Tenant ID** | In `certs/azure-config.txt` |
| **Subscription ID** | In `certs/azure-config.txt` |
| **Client/App ID** | In `certs/azure-config.txt` |
| **Certificate File** | `certs/service-principal-combined.pem` |

---

## 📝 Sample Pipeline Usage

```yaml
trigger: 
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  azureServiceConnection: 'your-cert-connection-name'

steps:
- task: AzureCLI@2
  displayName: 'Deploy to Azure'
  inputs:
    azureSubscription: $(azureServiceConnection)
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az group list
      echo "Authenticated successfully with certificate!"
```

---

## 🆘 Troubleshooting

### "Certificate verification failed"
```bash
# Check certificate is valid
openssl x509 -in certs/service-principal-cert.pem -noout -checkend 0

# Verify it has both cert and key
cat certs/service-principal-combined.pem
```

### "Authentication failed"
```bash
# Wait 2-3 minutes for Azure AD propagation, then retry
# Check the service principal exists
az ad sp show --id <APP_ID>
```

### "Authorization failed"
```bash
# Check permissions
az role assignment list --assignee <APP_ID> --output table

# Add permissions if missing
az role assignment create --assignee <APP_ID> --role Contributor --scope /subscriptions/<SUB_ID>
```

---

## 🔒 Security Checklist

- ✅ Certificate files are in `.gitignore`
- ✅ Never commit `*.pem`, `*.key` files
- ✅ Store certificates securely
- ✅ Set calendar reminder for cert expiry (1 year)
- ✅ Use least-privilege permissions
- ✅ Consider Azure Key Vault for production

---

## 📚 Available Documentation

| Document | Purpose |
|----------|---------|
| `QUICK-START.md` | This file - fast setup |
| `README.md` | Main documentation |
| `Azure-Certificate-Based-Auth-Guide.md` | Comprehensive guide |
| `certs/azure-config.txt` | Your specific configuration |

---

## ⏱️ Certificate Expiry

Your certificate is valid for **365 days** from generation.

**Set a reminder to renew before:**
```bash
# Check expiry date
openssl x509 -in certs/service-principal-cert.pem -noout -enddate
```

**To renew:**
1. Run `./generate-cert.sh` again
2. Upload new certificate to Azure
3. Update Azure DevOps service connection

---

## 🎓 Common Use Cases

### 1. CI/CD Pipeline
```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: $(serviceConnection)
    scriptType: 'bash'
    inlineScript: |
      az webapp deployment source config-zip \
        --src package.zip \
        --name myapp \
        --resource-group myrg
```

### 2. Infrastructure Deployment
```yaml
- task: AzureResourceManagerTemplateDeployment@3
  inputs:
    azureResourceManagerConnection: $(serviceConnection)
    subscriptionId: $(subscriptionId)
    resourceGroupName: 'myResourceGroup'
    location: 'East US'
    templateLocation: 'Linked artifact'
    csmFile: 'template.json'
```

### 3. Container Registry Push
```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: $(serviceConnection)
    scriptType: 'bash'
    inlineScript: |
      az acr login --name myregistry
      docker push myregistry.azurecr.io/myimage:latest
```

---

## 💡 Pro Tips

1. **Multiple Environments**
   - Create separate service principals for dev/staging/prod
   - Use different certificates for each environment

2. **Naming Convention**
   - Use descriptive names: `azure-devops-prod-cert-sp`
   - Include project name: `myproject-azure-cert-sp`

3. **Access Control**
   - Start with resource group scope, not subscription
   - Grant minimum required permissions

4. **Monitoring**
   - Check Azure Activity Logs regularly
   - Set up alerts for unusual activity

---

## ✅ Verification Steps

After setup, verify:

- [ ] Can run `./test-cert-auth.sh` successfully
- [ ] Service connection in Azure DevOps shows "Verified"
- [ ] Test pipeline runs without authentication errors
- [ ] Can list Azure resources in pipeline
- [ ] Certificate expiry reminder is set

---

## 🚀 You're Ready!

You now have certificate-based authentication configured for Azure DevOps!

**Next:**
1. Update your existing pipelines to use the new service connection
2. Remove any client secret-based connections
3. Document your setup for team members

**Need more details?** See `Azure-Certificate-Based-Auth-Guide.md`

---

**Last Updated:** December 11, 2024

