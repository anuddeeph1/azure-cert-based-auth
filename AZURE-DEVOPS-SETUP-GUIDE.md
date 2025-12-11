# Azure DevOps Service Connection Setup - Step-by-Step Guide

**Status:** Ready to configure  
**Certificate:** ✅ Tested and working  
**Date:** December 11, 2025

---

## 📋 Prerequisites Check

Before you start, verify you have:
- ✅ Access to Azure DevOps organization
- ✅ Project admin permissions in Azure DevOps
- ✅ File: `certs/service-principal-combined.pem`
- ✅ Configuration values (below)

---

## 🔑 Your Configuration Values (Copy These)

**IMPORTANT: You'll need these values. Keep this window open!**

```
Subscription ID:        baf89069-e8f3-46f8-b74e-c146931ce7a4
Subscription Name:      Microsoft Azure Sponsorship
Service Principal ID:   042aea62-c886-46a1-b2f8-25c9af22a2db
Tenant ID:              3d95acd6-b6ee-428e-a7a0-196120fc3c65
Certificate File:       certs/service-principal-combined.pem
```

---

## 🚀 Step-by-Step Setup

### Step 1: Access Azure DevOps

1. **Open your browser** and go to Azure DevOps:
   ```
   https://dev.azure.com
   ```

2. **Sign in** with your Azure credentials (anudeep.nalla@nirmata.com)

3. **Navigate to your organization and project**
   - Select your organization
   - Select the project where you want to use this service connection

---

### Step 2: Navigate to Service Connections

1. **Click on "Project Settings"** (gear icon in bottom-left corner)

2. **In the left sidebar**, under "Pipelines", click **"Service connections"**

3. You should see a page with existing service connections (if any)

**URL Pattern:**
```
https://dev.azure.com/{your-org}/{your-project}/_settings/adminservices
```

---

### Step 3: Create New Service Connection

1. **Click** the **"New service connection"** button (usually in top-right)

2. **A dialog will appear** with service connection types

3. **Scroll down and select** **"Azure Resource Manager"**

4. **Click "Next"**

---

### Step 4: Select Authentication Method

1. **You'll see several authentication options:**
   - Service principal (automatic)
   - Service principal (manual)  ← **SELECT THIS**
   - Managed identity
   - Publish profile

2. **Select** **"Service principal (manual)"**

3. **Click "Next"**

---

### Step 5: Choose Authentication Type

1. **You'll see two options:**
   - App registration or managed identity (automatic)
   - **Certificate** ← **SELECT THIS**

2. **Select** **"Certificate"**

---

### Step 6: Fill in Connection Details

Now you'll see a form. Fill it in **exactly** as shown below:

#### Environment
```
Azure Cloud  (default - don't change)
```

#### Scope Level
```
○ Management Group
● Subscription  ← SELECT THIS
○ Machine Learning Workspace
```

#### Subscription Details

**Subscription ID:**
```
baf89069-e8f3-46f8-b74e-c146931ce7a4
```
*(Copy-paste this exactly)*

**Subscription Name:**
```
Microsoft Azure Sponsorship
```
*(Copy-paste this exactly)*

---

#### Service Principal Details

**Service Principal Id:**
```
042aea62-c886-46a1-b2f8-25c9af22a2db
```
*(This is your Application/Client ID)*

---

#### Authentication

**Service principal key:**

This is where you upload your certificate!

1. **Click** the **"Browse"** or **"Choose File"** button

2. **Navigate to:**
   ```
   /Users/anudeepnalla/Downloads/novartis/azure-cert/novartis-azure-devops/certs/
   ```

3. **Select the file:**
   ```
   service-principal-combined.pem
   ```
   ⭐ **IMPORTANT:** Use the **combined** file, not the regular cert!

4. **Click "Open"**

5. You should see the filename displayed

---

#### Tenant ID

**Tenant ID:**
```
3d95acd6-b6ee-428e-a7a0-196120fc3c65
```
*(Copy-paste this exactly)*

---

#### Service Connection Name

**Service connection name:**
```
azure-cert-sp-connection
```
*(Or choose your own meaningful name)*

**Description (optional):**
```
Certificate-based service principal for Azure deployments
```

---

#### Additional Options

**☐ Grant access permission to all pipelines**

- ✅ **Check this box** if you want all pipelines to use this connection
- ⬜ **Leave unchecked** if you want to grant access per-pipeline (more secure)

**Recommendation:** Leave unchecked for better security, then grant access to specific pipelines as needed.

---

### Step 7: Verify Connection

1. **Click** the **"Verify"** button

2. **Wait** for verification (usually 5-10 seconds)

3. **Expected result:**
   ```
   ✅ Verification Succeeded
   ```

4. **If verification succeeds:** Great! Proceed to next step.

5. **If verification fails:** See troubleshooting section below.

---

### Step 8: Save Connection

1. **Click** the **"Verify and save"** button

2. The connection will be created

3. You should see it in your list of service connections

4. **Status should show:** ✅ Ready

---

## ✅ Verification Checklist

After saving, verify:

- [ ] Service connection appears in the list
- [ ] Status shows as "Ready" or has a green checkmark
- [ ] Connection name is correct
- [ ] You can see subscription details

---

## 🧪 Test the Connection

### Option 1: Test with Quick Pipeline

Create a new pipeline with this YAML:

```yaml
trigger: none

pool:
  vmImage: 'ubuntu-latest'

variables:
  azureConnection: 'azure-cert-sp-connection'  # Your connection name

steps:
- task: AzureCLI@2
  displayName: 'Test Certificate Authentication'
  inputs:
    azureSubscription: $(azureConnection)
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      echo "================================================"
      echo "Testing Certificate-Based Authentication"
      echo "================================================"
      echo ""
      echo "Current Account:"
      az account show --output table
      echo ""
      echo "Resource Groups:"
      az group list --output table
      echo ""
      echo "✅ Certificate authentication is working!"
      echo "================================================"
```

**To run:**
1. Create new pipeline in Azure DevOps
2. Paste the YAML above
3. Save and run
4. Should complete successfully with green checkmark ✅

---

### Option 2: Test with Provided Pipeline

We already have a comprehensive test pipeline:

1. **Commit the test pipeline to your repo:**
   ```bash
   git add azure-pipelines-cert-test.yml
   git commit -m "Add certificate auth test pipeline"
   git push
   ```

2. **In Azure DevOps:**
   - Go to Pipelines
   - Click "New pipeline"
   - Select your repository
   - Select "Existing Azure Pipelines YAML file"
   - Choose `azure-pipelines-cert-test.yml`
   - Update the service connection name in line 11 to match yours
   - Run the pipeline

3. **Expected result:**
   - All tasks should complete successfully ✅
   - You should see resource groups listed
   - Authentication test should pass

---

## 🔧 Troubleshooting

### Verification Failed: "Invalid credentials"

**Possible causes:**
1. Wrong Client ID, Tenant ID, or Subscription ID
2. Certificate not uploaded correctly
3. Certificate expired

**Solutions:**
```bash
# Verify certificate is valid
openssl x509 -in certs/service-principal-cert.pem -noout -checkend 0

# Double-check IDs in azure-config.txt
cat certs/azure-config.txt

# Re-upload the COMBINED certificate (not just cert)
# File: certs/service-principal-combined.pem
```

---

### Verification Failed: "Access denied"

**Possible causes:**
1. Service principal doesn't have permissions
2. RBAC hasn't propagated yet

**Solutions:**
```bash
# Check role assignments
az role assignment list --assignee 042aea62-c886-46a1-b2f8-25c9af22a2db --output table

# If no role shows, re-assign:
az role assignment create \
  --assignee 042aea62-c886-46a1-b2f8-25c9af22a2db \
  --role Contributor \
  --scope /subscriptions/baf89069-e8f3-46f8-b74e-c146931ce7a4

# Wait 5-10 minutes for propagation, then try again
```

---

### "Cannot find certificate file"

**Solution:**
```bash
# Verify file exists
ls -lh certs/service-principal-combined.pem

# If missing, regenerate:
cat certs/service-principal-cert.pem certs/service-principal-key.pem > certs/service-principal-combined.pem
```

---

### "Wrong certificate file"

**Common mistake:** Uploading `service-principal-cert.pem` instead of `service-principal-combined.pem`

**Solution:**
- Azure DevOps needs the COMBINED file (cert + private key)
- Make sure you're uploading: `service-principal-combined.pem` ⭐
- NOT: `service-principal-cert.pem` ❌

---

### Connection saves but doesn't work in pipelines

**Solution:**
1. Edit the service connection
2. Re-verify the connection
3. Check pipeline YAML uses correct connection name
4. Ensure pipeline has permission to use the connection:
   - Go to service connection settings
   - Check "Pipeline permissions"
   - Add your pipeline if needed

---

## 📊 Expected Results

### After Successful Setup

**Service Connection List:**
```
Name: azure-cert-sp-connection
Type: Azure Resource Manager
Authentication: Service Principal (Certificate)
Status: ✅ Ready
Subscription: Microsoft Azure Sponsorship
```

**When Used in Pipeline:**
```
✅ Authentication successful
✅ Can list Azure resources
✅ Can deploy to Azure
✅ Tasks complete successfully
```

---

## 🎯 Next Steps After Setup

### 1. Test with Simple Pipeline
Run the test YAML provided above to verify everything works.

### 2. Grant Pipeline Permissions (if needed)
If you didn't grant access to all pipelines:
1. Go to service connection
2. Click on it → Security
3. Add specific pipelines that should use it

### 3. Update Existing Pipelines
Replace any password/secret-based authentication with your new certificate-based connection.

### 4. Document for Team
Share this guide with team members who need to:
- Create pipelines
- Understand the authentication method
- Troubleshoot issues

---

## 📝 Service Connection Configuration Summary

Once created, your service connection will have:

```yaml
Name:              azure-cert-sp-connection
Type:              Azure Resource Manager
Authentication:    Service Principal (Certificate)
Scope:             Subscription
Subscription ID:   baf89069-e8f3-46f8-b74e-c146931ce7a4
Subscription Name: Microsoft Azure Sponsorship
Tenant:            3d95acd6-b6ee-428e-a7a0-196120fc3c65
Service Principal: 042aea62-c886-46a1-b2f8-25c9af22a2db
Certificate:       ✅ Uploaded (expires Dec 11, 2026)
Permissions:       Contributor
Status:            ✅ Verified
```

---

## 🔐 Security Best Practices

After setup:

1. **Audit Usage**
   - Regularly review which pipelines use this connection
   - Check pipeline permissions on the service connection

2. **Monitor Activity**
   - Review Azure Activity Logs for service principal actions
   - Set up alerts for suspicious activity

3. **Limit Scope**
   - Consider creating resource-group-scoped connections for specific projects
   - Use different service principals for dev/staging/prod

4. **Certificate Management**
   - Set reminder for renewal (November 11, 2026)
   - Test renewal process in advance
   - Keep backup of certificates secure

---

## 💡 Pro Tips

### Tip 1: Multiple Connections
You can create multiple service connections for different purposes:
- `azure-cert-dev` - Development environment
- `azure-cert-staging` - Staging environment
- `azure-cert-prod` - Production environment

### Tip 2: Connection Naming
Use meaningful names that indicate:
- Authentication method (cert vs secret)
- Environment (dev/staging/prod)
- Scope (subscription vs resource group)

Example: `azure-cert-prod-subscription`

### Tip 3: Pipeline Variables
Reference connection as a variable:
```yaml
variables:
  azureConnection: 'azure-cert-sp-connection'

steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: $(azureConnection)
```

### Tip 4: Documentation
Keep the service connection documentation updated:
- Which projects/repos use it
- What permissions it has
- Certificate expiry date
- Contact person for issues

---

## 📞 Quick Reference

**Service Connection Type:**
```
Azure Resource Manager → Service principal (manual) → Certificate
```

**Required Values:**
```
Subscription ID:    baf89069-e8f3-46f8-b74e-c146931ce7a4
Service Principal:  042aea62-c886-46a1-b2f8-25c9af22a2db
Tenant ID:          3d95acd6-b6ee-428e-a7a0-196120fc3c65
Certificate:        certs/service-principal-combined.pem
```

**Verify Command:**
```bash
cat certs/azure-config.txt
```

**Test Command:**
```bash
./test-cert-auth.sh
```

---

## ✅ Setup Completion Checklist

- [ ] Navigated to Azure DevOps Service Connections
- [ ] Created new Azure Resource Manager connection
- [ ] Selected Service Principal (manual)
- [ ] Selected Certificate authentication
- [ ] Filled in all required fields correctly
- [ ] Uploaded service-principal-combined.pem file
- [ ] Clicked Verify (verification succeeded ✅)
- [ ] Saved the connection
- [ ] Connection appears in list with "Ready" status
- [ ] Tested with simple pipeline
- [ ] Pipeline authentication successful
- [ ] Documented connection for team

---

## 🎉 Success Indicators

You'll know it's working when:

1. **Verification succeeds** during creation ✅
2. **Status shows "Ready"** in connection list ✅
3. **Pipeline runs successfully** without auth errors ✅
4. **Can see Azure resources** in pipeline logs ✅
5. **Deployments complete successfully** ✅

---

## 📚 Additional Resources

- **Your Configuration:** `certs/azure-config.txt`
- **Test Scripts:** `test-cert-auth.sh` or `test-cert-auth.py`
- **Test Pipeline:** `azure-pipelines-cert-test.yml`
- **Main Docs:** `README.md`
- **Troubleshooting:** `Azure-Certificate-Based-Auth-Guide.md`

---

**Ready to proceed? Follow the steps above to set up your service connection!**

**Estimated Time:** 5-10 minutes  
**Difficulty:** Easy (just copy-paste values)  
**Result:** Working certificate-based authentication in Azure DevOps! 🚀

---

**Questions or issues?** Check the Troubleshooting section above or refer to the main documentation files.

