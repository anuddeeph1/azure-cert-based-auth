# How Certificate-Based Authentication Works with Terraform

## 🔐 Overview

When you run Terraform locally, it uses your **certificate-based Azure authentication** to create resources. Here's exactly how it works.

---

## 🔄 Authentication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. YOU RUN TERRAFORM                                            │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. AZURE CLI AUTHENTICATION                                     │
│                                                                 │
│    $ az login --service-principal \                             │
│        --username <CLIENT_ID> \                                 │
│        --tenant <TENANT_ID> \                                   │
│        --certificate <CERT_FILE>                                │
│                                                                 │
│    This authenticates you using your certificate!              │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. TERRAFORM READS AZURE CLI CREDENTIALS                        │
│                                                                 │
│    Terraform checks: ~/.azure/ directory                        │
│    Finds: Active Azure CLI session                             │
│    Uses: Your certificate-authenticated session                │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. TERRAFORM CALLS AZURE API                                    │
│                                                                 │
│    Every Terraform operation sends API calls to Azure:         │
│    - Create Resource Group                                      │
│    - Create Virtual Network                                     │
│    - Create AKS Cluster                                         │
│    etc.                                                         │
│                                                                 │
│    Each API call includes authentication from Step 2           │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. AZURE VALIDATES CERTIFICATE                                  │
│                                                                 │
│    Azure Active Directory checks:                              │
│    ✓ Certificate is valid                                      │
│    ✓ Certificate belongs to service principal                  │
│    ✓ Service principal has Contributor permissions             │
│    ✓ Certificate not expired                                   │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. RESOURCES CREATED                                            │
│                                                                 │
│    ✅ Resource Group                                            │
│    ✅ Virtual Network                                           │
│    ✅ Subnets                                                   │
│    ✅ AKS Cluster                                               │
│    ✅ Node Pool 1 (System)                                      │
│    ✅ Node Pool 2 (User)                                        │
│    ✅ Log Analytics                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📝 Step-by-Step Explanation

### Step 1: Azure CLI Authentication

When you run:
```bash
az login --service-principal \
  --username 042aea62-c886-46a1-b2f8-25c9af22a2db \
  --tenant 3d95acd6-b6ee-428e-a7a0-196120fc3c65 \
  --certificate ../../certs/service-principal-combined.pem
```

**What happens:**
1. Azure CLI reads your certificate file
2. Extracts the public certificate and private key
3. Signs a request with the private key
4. Sends authentication request to Azure AD
5. Azure AD validates the signature using the public certificate (stored in Azure)
6. Returns an access token valid for 1 hour
7. Stores credentials in `~/.azure/` directory

### Step 2: Terraform Uses Azure CLI Credentials

In `providers.tf`, you have:
```hcl
provider "azurerm" {
  features { }
  
  # NO credentials specified here!
  # Terraform automatically uses Azure CLI credentials
}
```

**What Terraform does:**
1. Checks for Azure CLI authentication: `~/.azure/azureProfile.json`
2. Finds active session for service principal: `042aea62-c886-46a1-b2f8-25c9af22a2db`
3. Uses the access token from Azure CLI
4. Refreshes token automatically when it expires

### Step 3: Terraform Creates Resources

When you run `terraform apply`:

```bash
terraform apply

# Terraform makes API calls like:
POST https://management.azure.com/subscriptions/{subscription-id}/resourceGroups/{name}
  Authorization: Bearer <access-token-from-certificate-auth>
  
POST https://management.azure.com/.../managedClusters/{aks-name}
  Authorization: Bearer <access-token-from-certificate-auth>
```

**Every API call includes:**
- `Authorization` header with the access token
- Access token was obtained via certificate authentication
- Token represents service principal: `042aea62-c886-46a1-b2f8-25c9af22a2db`
- Token has Contributor permissions on subscription

---

## 🔑 Where is the Certificate Used?

### Certificate Location
```
/Users/anudeepnalla/Downloads/novartis/azure-cert/
novartis-azure-devops/certs/service-principal-combined.pem
```

### Certificate Contents
```
-----BEGIN CERTIFICATE-----
<Your public certificate>
-----END CERTIFICATE-----
-----BEGIN PRIVATE KEY-----
<Your private key>
-----END PRIVATE KEY-----
```

### How Each Part is Used

**Public Certificate (uploaded to Azure AD):**
- Stored in Azure Active Directory
- Used by Azure to verify your identity
- Safe to share (but we don't for security)

**Private Key (stays on your machine):**
- Never leaves your computer
- Used to sign authentication requests
- **MUST keep secret!**

---

## 🆚 Certificate Auth vs Other Methods

### Your Current Setup (Certificate)
```bash
# Login
az login --service-principal --certificate cert.pem

# Terraform uses it automatically
terraform apply
```

**Pros:**
✅ More secure (private key never transmitted)
✅ No secrets in code
✅ Easy to rotate
✅ Industry best practice

### Alternative: Client Secret (not used)
```bash
# Would need to store secret
export ARM_CLIENT_SECRET="secret-value"

# Or hardcode in providers.tf (BAD!)
provider "azurerm" {
  client_secret = "secret-value"  # ❌ Don't do this!
}
```

**Cons:**
❌ Less secure
❌ Secret can be intercepted
❌ Easy to leak in logs/code

---

## 🔍 How to Verify It's Working

### Check Current Authentication
```bash
# See who you're logged in as
az account show

# Output shows:
{
  "user": {
    "name": "042aea62-c886-46a1-b2f8-25c9af22a2db",
    "type": "servicePrincipal"  # ← Certificate-authenticated!
  }
}
```

### Check Terraform Authentication
```bash
cd terraform-aks-deployment/terraform

# Test authentication
terraform plan

# If it works, certificate auth is working!
# Terraform is using your certificate-authenticated session
```

### Check API Calls (Debug Mode)
```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform plan 2>&1 | grep "Authorization"

# You'll see API calls with Bearer tokens
# Those tokens came from certificate authentication!
```

---

## 📊 Two Node Pools Configuration

Your Terraform now creates **TWO** node pools:

### Node Pool 1: System Pool (Required)
```hcl
# In main.tf - default_node_pool block
default_node_pool {
  name    = "systempool"
  vm_size = "Standard_D4s_v3"  # 4 vCPUs, 16 GB
  min_count = 2
  max_count = 5
  # Runs system components: CoreDNS, metrics-server, etc.
}
```

### Node Pool 2: User Pool (Your Apps)
```hcl
# In main.tf - azurerm_kubernetes_cluster_node_pool resource
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count     = var.enable_user_node_pool ? 1 : 0
  name      = "userpool"
  vm_size   = "Standard_D8s_v3"  # 8 vCPUs, 32 GB
  min_count = 2
  max_count = 10
  mode      = "User"  # ← For application workloads
}
```

### Why Two Node Pools?

**System Pool:**
- Purpose: Kubernetes system components
- Always required
- Smaller VMs are fine
- Should not run your applications

**User Pool:**
- Purpose: Your applications
- Optional but recommended
- Larger VMs for your workloads
- Can be scaled independently
- Can be deleted without affecting system

---

## 🔐 Security Flow

```
Your Computer                    Azure Active Directory
─────────────                    ──────────────────────
                                 
[Certificate File]               [Public Certificate]
   (Private Key)                 (Stored in Azure)
        │                                │
        │ 1. Sign request                │
        │    with private key            │
        ├────────────────────────────────►│
        │                                │
        │                          2. Verify signature
        │                             with public cert
        │                                │
        │ 3. Return access token         │
        │◄────────────────────────────────┤
        │                                │
        ▼                                │
   [Terraform]                           │
        │                                │
        │ 4. Use token for API calls     │
        ├────────────────────────────────►│
        │                                │
        │ 5. Resources created           │
        │◄────────────────────────────────┤
        ▼
  [AKS Cluster]
  [2 Node Pools]
```

---

## 💡 Key Points

### Certificate is Used For:
1. ✅ **Initial authentication** with Azure AD
2. ✅ **Getting access tokens** (valid for 1 hour)
3. ✅ **Automatic token refresh** by Azure CLI

### Certificate is NOT:
1. ❌ Sent with every Terraform API call
2. ❌ Stored in Terraform state
3. ❌ Embedded in created resources

### Where Credentials Are Stored:
```
~/.azure/
├── azureProfile.json       ← Current subscription
├── clouds.config           ← Azure cloud config
└── msal_token_cache.json   ← Access tokens (encrypted)
```

---

## 🧪 Test It Yourself

### 1. Check Authentication Method
```bash
# View current auth
az account show --query "{Name:name, User:user.name, Type:user.type}"

# Output should show:
{
  "Type": "servicePrincipal"  # ← Certificate-based!
}
```

### 2. Test Terraform
```bash
cd terraform-aks-deployment/terraform

# Initialize (one time)
terraform init

# Test authentication
terraform plan

# If plan works, certificate auth is working!
```

### 3. Verify Certificate Expiry
```bash
# Check when certificate expires
openssl x509 -in ../../certs/service-principal-cert.pem -noout -enddate

# Output: notAfter=Dec 11 06:13:47 2026 GMT
```

---

## ❓ FAQs

### Q: Does Terraform need direct access to the certificate?
**A:** No! Terraform uses Azure CLI's authentication. Azure CLI already authenticated with the certificate.

### Q: What if my certificate expires?
**A:** You'll get authentication errors. Generate a new certificate and upload to Azure (see main README.md).

### Q: Can I use this in Azure DevOps pipelines?
**A:** Yes! But the pipeline has a bug with certificates. Use the pipeline with proper certificate handling or use client secret for pipelines.

### Q: Is this secure for production?
**A:** Yes! Certificate-based auth is MORE secure than client secrets. Just keep your private key safe!

### Q: How long does the access token last?
**A:** 1 hour. Azure CLI automatically refreshes it, so Terraform runs longer than 1 hour still work.

---

## 📚 Summary

**Your Terraform Setup:**
```
Certificate on disk
    ↓
Azure CLI login (az login --certificate)
    ↓
Access token stored in ~/.azure/
    ↓
Terraform reads Azure CLI credentials
    ↓
Terraform makes API calls with token
    ↓
Azure validates token (from certificate auth)
    ↓
Resources created (including 2 node pools!)
```

**Authentication Chain:**
```
Certificate → Azure AD → Access Token → Terraform → Azure API → AKS Cluster
```

---

**Now you understand how your certificate enables Terraform to create resources securely!** 🎉

