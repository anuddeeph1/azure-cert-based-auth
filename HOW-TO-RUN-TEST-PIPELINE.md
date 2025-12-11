# How to Run the Test Pipeline

Your service connection is created! Now let's test it with a pipeline.

---

## 🎯 **Method 1: Quick Test (Recommended)**

### **Step 1: Commit the Test Pipeline**

```bash
cd /Users/anudeepnalla/Downloads/novartis/azure-cert/novartis-azure-devops

# Initialize git if not already done
git init

# Add the test pipeline
git add test-pipeline.yml

# Commit it
git commit -m "Add certificate auth test pipeline"

# Push to your Azure DevOps repo
git remote add origin https://nirmata@dev.azure.com/nirmata/anudeep/_git/your-repo-name
git push -u origin main
```

### **Step 2: Create Pipeline in Azure DevOps**

1. **Go to Azure DevOps:**
   ```
   https://dev.azure.com/nirmata/anudeep/_build
   ```

2. **Click "New pipeline"** (top right)

3. **Select your repository:**
   - If using Azure Repos: Select your repository
   - If using GitHub/other: Follow the prompts

4. **Configure your pipeline:**
   - Select **"Existing Azure Pipelines YAML file"**
   - Choose the branch (usually `main` or `master`)
   - Path: `/test-pipeline.yml`

5. **Review and Run:**
   - Click **"Run"**
   - The pipeline will start executing!

### **Step 3: Watch It Run**

You should see:
- ✅ Test 1: Verify Azure Login
- ✅ Test 2: List Subscriptions
- ✅ Test 3: List Resource Groups
- ✅ Test 4: Check Permissions
- ✅ Test 5: List Azure Resources
- ✅ Test 6: PowerShell Access
- 🎉 Summary

All steps should complete successfully with green checkmarks!

---

## 🎯 **Method 2: Copy-Paste Test (No Git Required)**

If you don't want to commit files yet, you can create a pipeline directly in the UI:

### **Step 1: Go to Pipelines**

```
https://dev.azure.com/nirmata/anudeep/_build
```

### **Step 2: New Pipeline**

1. Click **"New pipeline"**
2. Select **"Azure Repos Git"** (or your source)
3. Select your repository (or create a new one)
4. Select **"Starter pipeline"**

### **Step 3: Replace YAML**

Replace everything with this simple test:

```yaml
trigger: none

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: AzureCLI@2
  displayName: 'Test Certificate Authentication'
  inputs:
    azureSubscription: 'azure-cert-sp-connection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      echo "================================================"
      echo "Testing Certificate-Based Authentication"
      echo "================================================"
      echo ""
      echo "1. Current Account:"
      az account show --output table
      echo ""
      echo "2. Resource Groups:"
      az group list --output table
      echo ""
      echo "3. Service Principal Info:"
      SP_ID=$(az account show --query user.name -o tsv)
      echo "   Service Principal: $SP_ID"
      echo ""
      echo "4. Role Assignments:"
      az role assignment list --assignee $SP_ID --output table
      echo ""
      echo "================================================"
      echo "✅ Certificate Authentication Working!"
      echo "================================================"
```

### **Step 4: Save and Run**

1. Click **"Save and run"**
2. Add a commit message: "Test certificate authentication"
3. Click **"Save and run"** again
4. Watch it execute!

---

## 🎯 **Method 3: Verify Service Connection First**

Before running a pipeline, verify the connection in the UI:

### **Step 1: Go to Service Connections**

```
https://dev.azure.com/nirmata/anudeep/_settings/adminservices
```

### **Step 2: Find Your Connection**

You should see:
- **Name:** azure-cert-sp-connection
- **Type:** Azure Resource Manager
- **Authentication:** Service Principal (Certificate)

### **Step 3: Click on It**

- Click on the service connection name
- You should see details:
  - Subscription: Microsoft Azure Sponsorship
  - Service Principal ID: 042aea62-c886-46a1-b2f8-25c9af22a2db
  - Authentication type: Certificate

### **Step 4: Test Connection (Optional)**

Some versions of Azure DevOps have a "Verify" button:
- Click it to test the connection
- Should show: ✅ "Verification succeeded"

---

## 🧪 **What the Test Pipeline Does**

The test pipeline (`test-pipeline.yml`) performs these checks:

```
Stage: Verify Authentication
  ├─ Test 1: Verify Azure Login
  │  └─ Confirms certificate authentication works
  │
  ├─ Test 2: List Subscriptions  
  │  └─ Shows accessible subscriptions
  │
  ├─ Test 3: List Resource Groups
  │  └─ Lists all 13+ resource groups
  │
  ├─ Test 4: Check Permissions
  │  └─ Verifies Contributor role
  │
  ├─ Test 5: List Resources
  │  └─ Shows accessible Azure resources
  │
  ├─ Test 6: PowerShell Access
  │  └─ Tests Azure PowerShell cmdlets
  │
  └─ Summary
     └─ Shows overall success
```

---

## ✅ **Expected Results**

When the pipeline runs successfully, you'll see:

```
✅ Test 1: Verify Azure Login - PASSED
✅ Test 2: List Subscriptions - PASSED  
✅ Test 3: List Resource Groups - PASSED (13 groups found)
✅ Test 4: Check Permissions - PASSED (Contributor role)
✅ Test 5: List Azure Resources - PASSED
✅ Test 6: PowerShell Access - PASSED

🎉 ALL TESTS PASSED! 🎉

Certificate-Based Authentication Summary:
  ✅ Authentication successful
  ✅ Subscription access verified
  ✅ Resource groups accessible
  ✅ RBAC permissions confirmed
  ✅ PowerShell integration working
  ✅ Azure CLI working
```

---

## 🔧 **Troubleshooting**

### **Pipeline Can't Find Service Connection**

**Error:** `Could not find a service connection with name 'azure-cert-sp-connection'`

**Solutions:**
1. Check the exact name in Azure DevOps service connections page
2. Update the pipeline YAML with the correct name
3. Grant the pipeline permission to use the connection

### **Permission Denied**

**Error:** `The pipeline is not valid. Job: could not be started because the user does not have permission`

**Solution:**
1. Go to the service connection
2. Click "Security" tab
3. Click "Pipeline permissions"
4. Add your pipeline or check "Grant access to all pipelines"

### **Authentication Failed in Pipeline**

**Error:** `Failed to authenticate with Azure`

**Solutions:**
1. Wait 2-3 minutes (Azure AD propagation)
2. Verify service principal permissions:
   ```bash
   az role assignment list --assignee 042aea62-c886-46a1-b2f8-25c9af22a2db
   ```
3. Check certificate hasn't expired:
   ```bash
   openssl x509 -in certs/service-principal-cert.pem -noout -checkend 0
   ```

---

## 📊 **Pipeline Performance**

Expected execution time:
- Total: ~2-3 minutes
- Each test: ~10-30 seconds
- Overhead: Agent initialization (~30 seconds)

---

## 🎯 **After Testing**

Once the test pipeline passes:

1. ✅ Your setup is fully verified
2. ✅ You can use the service connection in production pipelines
3. ✅ Share the connection with your team
4. ✅ Start deploying to Azure!

---

## 💡 **Using in Your Pipelines**

To use this service connection in any pipeline:

```yaml
steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: 'azure-cert-sp-connection'  # Your connection name
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # Your Azure commands here
      az webapp create ...
      az storage account create ...
      # etc.
```

Or with Azure PowerShell:

```yaml
steps:
- task: AzurePowerShell@5
  inputs:
    azureSubscription: 'azure-cert-sp-connection'
    ScriptType: 'InlineScript'
    Inline: |
      # Your PowerShell commands
      New-AzWebApp ...
      New-AzStorageAccount ...
    azurePowerShellVersion: 'LatestVersion'
```

---

## 🚀 **Next Steps**

1. **Run the test pipeline** (using any method above)
2. **Verify all tests pass**
3. **Use in your real pipelines**
4. **Deploy to Azure!**

---

**Need help? Let me know which method you want to use and I can guide you through it!**

