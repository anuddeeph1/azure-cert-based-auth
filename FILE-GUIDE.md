# 📁 File Guide - What Each File Does

## 🚀 START HERE

### For Absolute Beginners
**Start with:** `QUICK-START.md`
- Fastest way to get running (5 minutes)
- Minimal explanation, maximum action
- Perfect if you just want it working

### For Complete Setup
**Run:** `./setup-azure-cert-auth.sh`
- Automated setup script
- Guides you through every step
- Tests everything automatically

---

## 📚 Documentation Files

### `README.md`
**Purpose:** Main project documentation  
**Use when:** You need general overview and reference  
**Contains:**
- Prerequisites checklist
- Step-by-step manual setup instructions
- Security best practices
- Troubleshooting guide
- Quick reference commands

### `QUICK-START.md` ⭐ START HERE
**Purpose:** Super fast setup guide  
**Use when:** You want to get started immediately  
**Contains:**
- 5-minute setup instructions
- Quick configuration steps
- Common troubleshooting
- Testing checklist

### `Azure-Certificate-Based-Auth-Guide.md`
**Purpose:** Comprehensive reference guide  
**Use when:** You need detailed explanations  
**Contains:**
- Complete OpenSSL commands with explanations
- Detailed Azure setup procedures
- Multiple testing methods
- Security best practices
- Production recommendations
- Troubleshooting in depth

### `WORKFLOW-DIAGRAM.md`
**Purpose:** Visual workflow and architecture  
**Use when:** You need to understand how it works  
**Contains:**
- System architecture diagrams
- Authentication flow charts
- Component interaction diagrams
- Security layer visualization
- Troubleshooting decision trees

### `FILE-GUIDE.md` (This File)
**Purpose:** Navigation guide for all files  
**Use when:** You're not sure which file to use  
**Contains:**
- Description of every file
- When to use each file
- Recommended workflow

---

## 🔧 Executable Scripts

### `setup-azure-cert-auth.sh` ⭐ RECOMMENDED
**Purpose:** Complete automated setup  
**Use when:** You want everything done automatically  
**What it does:**
1. Checks prerequisites (Azure CLI, OpenSSL)
2. Generates certificates
3. Creates Azure service principal
4. Uploads certificate to Azure AD
5. Assigns RBAC permissions
6. Tests authentication
7. Saves configuration details
8. Offers to run additional tests

**How to run:**
```bash
chmod +x setup-azure-cert-auth.sh
./setup-azure-cert-auth.sh
```

**Time:** ~3-5 minutes (with user input)

---

### `generate-cert.sh`
**Purpose:** Generate OpenSSL certificates only  
**Use when:** You only need to create certificates  
**What it does:**
1. Prompts for certificate details (CN, Org, etc.)
2. Generates RSA 4096-bit certificate
3. Creates multiple certificate formats:
   - PEM format (for CLI/Python)
   - DER format (for Azure Portal)
   - Combined format (for Azure DevOps)
4. Displays certificate thumbprint
5. Creates .gitignore for security

**How to run:**
```bash
chmod +x generate-cert.sh
./generate-cert.sh
```

**Output files:**
- `certs/service-principal-key.pem`
- `certs/service-principal-cert.pem`
- `certs/service-principal-combined.pem` ← Use for Azure DevOps
- `certs/service-principal-cert.cer` ← Use for Azure Portal

**Time:** ~30 seconds

---

### `test-cert-auth.sh`
**Purpose:** Test certificate authentication  
**Use when:** You want to verify everything is working  
**What it does:**
1. Validates certificate is not expired
2. Attempts Azure CLI login with certificate
3. Lists available subscriptions
4. Tests resource group access
5. Checks RBAC permissions
6. Displays configuration summary

**How to run:**
```bash
chmod +x test-cert-auth.sh
./test-cert-auth.sh
```

**You'll need:**
- Tenant ID
- Client/Application ID
- Subscription ID (optional)

**Time:** ~1-2 minutes

---

### `test-cert-auth.py`
**Purpose:** Test certificate authentication with Python SDK  
**Use when:** You want to test with Python/SDK  
**What it does:**
1. Checks Azure SDK packages
2. Creates certificate credential
3. Tests token acquisition
4. Lists subscriptions
5. Lists resource groups
6. Lists resources
7. Verifies API access

**How to run:**
```bash
pip install azure-identity azure-mgmt-resource
chmod +x test-cert-auth.py
./test-cert-auth.py
```

**Or:**
```bash
python test-cert-auth.py
```

**Time:** ~1-2 minutes

---

## 📋 Configuration Files

### `azure-pipelines-cert-test.yml`
**Purpose:** Azure DevOps pipeline for testing  
**Use when:** You want to test in Azure DevOps pipeline  
**What it does:**
1. Tests Azure CLI authentication
2. Lists subscriptions
3. Lists resource groups
4. Checks service principal permissions
5. Tests PowerShell access
6. Validates deployment permissions
7. Lists resources by type

**How to use:**
1. Update service connection name in file
2. Create new pipeline in Azure DevOps
3. Point to this YAML file
4. Run pipeline

**Stages:**
- `TestCertificateAuth` - Validates connection
- `TestResourceOperations` - Tests resource operations

---

## 📝 Generated Files (After Running Scripts)

### `certs/` Directory
**Created by:** `generate-cert.sh` or `setup-azure-cert-auth.sh`  
**Contains:**

#### `service-principal-key.pem`
- **What:** Private key (RSA 4096-bit)
- **Use:** Keep secure, do NOT share
- **Security:** Never commit to Git

#### `service-principal-cert.pem`
- **What:** Public certificate (PEM format)
- **Use:** Upload to Azure AD with Azure CLI
- **Format:** Base64-encoded X.509

#### `service-principal-combined.pem` ⭐
- **What:** Certificate + Private Key combined
- **Use:** Upload to Azure DevOps service connection
- **Security:** Keep secure, do NOT share

#### `service-principal-cert.cer`
- **What:** Public certificate (DER format)
- **Use:** Upload to Azure Portal
- **Format:** Binary X.509

#### `azure-config.txt`
- **What:** Your configuration details
- **Contains:** Tenant ID, Client ID, Subscription ID, thumbprint
- **Use:** Reference when configuring Azure DevOps

#### `.gitignore`
- **What:** Git ignore file for certificates
- **Purpose:** Prevent accidental commits of sensitive files

---

## 🗺️ Recommended Workflows

### Workflow 1: First-Time Setup (Recommended)
```
1. Read QUICK-START.md (2 min)
2. Run ./setup-azure-cert-auth.sh (5 min)
3. Configure Azure DevOps using azure-config.txt (2 min)
4. Run test pipeline using azure-pipelines-cert-test.yml (2 min)
```
**Total Time:** ~10-15 minutes

---

### Workflow 2: Manual Step-by-Step Setup
```
1. Read README.md for prerequisites (5 min)
2. Run ./generate-cert.sh (1 min)
3. Manually create service principal in Azure (5 min)
4. Upload certificate to Azure Portal (2 min)
5. Assign RBAC permissions (2 min)
6. Run ./test-cert-auth.sh to verify (2 min)
7. Configure Azure DevOps (3 min)
8. Run test pipeline (2 min)
```
**Total Time:** ~20-25 minutes

---

### Workflow 3: Certificate-Only Generation
```
1. Run ./generate-cert.sh (1 min)
2. Use generated certificates for your own setup
```
**Total Time:** ~1 minute

---

### Workflow 4: Testing Existing Setup
```
1. Run ./test-cert-auth.sh (2 min)
   OR
2. Run ./test-cert-auth.py (2 min)
   OR
3. Run azure-pipelines-cert-test.yml in Azure DevOps (2 min)
```
**Total Time:** ~2 minutes

---

## 📖 Reading Order for Learning

### Quick Learner (Just make it work)
1. `QUICK-START.md`
2. Run `setup-azure-cert-auth.sh`
3. Done!

### Thorough Learner (Understand everything)
1. `README.md` - Get overview
2. `Azure-Certificate-Based-Auth-Guide.md` - Deep dive
3. `WORKFLOW-DIAGRAM.md` - Understand architecture
4. Run `setup-azure-cert-auth.sh` - Practice
5. `azure-pipelines-cert-test.yml` - See it in action

### Visual Learner (See how it works)
1. `WORKFLOW-DIAGRAM.md` - See the flow
2. `QUICK-START.md` - Quick implementation
3. Run `setup-azure-cert-auth.sh` - Hands-on
4. `README.md` - Fill in details

---

## 🎯 Files by Task

### Task: "I want to set everything up"
→ `./setup-azure-cert-auth.sh`

### Task: "I just need certificates"
→ `./generate-cert.sh`

### Task: "I need to test if it works"
→ `./test-cert-auth.sh` or `./test-cert-auth.py`

### Task: "I want to understand how it works"
→ `WORKFLOW-DIAGRAM.md` + `Azure-Certificate-Based-Auth-Guide.md`

### Task: "I'm having problems"
→ `README.md` (Troubleshooting section)

### Task: "I need quick reference"
→ `README.md` (Quick Reference section)

### Task: "I want to test in pipeline"
→ `azure-pipelines-cert-test.yml`

### Task: "Where are my configuration details?"
→ `certs/azure-config.txt` (generated after setup)

---

## 📱 Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│              CERTIFICATE AUTH QUICK REF                  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Setup (First Time):                                     │
│    ./setup-azure-cert-auth.sh                            │
│                                                          │
│  Generate Cert Only:                                     │
│    ./generate-cert.sh                                    │
│                                                          │
│  Test Authentication:                                    │
│    ./test-cert-auth.sh                                   │
│    ./test-cert-auth.py                                   │
│                                                          │
│  Configuration File:                                     │
│    certs/azure-config.txt                                │
│                                                          │
│  For Azure DevOps:                                       │
│    Upload: certs/service-principal-combined.pem          │
│                                                          │
│  For Azure Portal:                                       │
│    Upload: certs/service-principal-cert.cer              │
│                                                          │
│  Check Cert Expiry:                                      │
│    openssl x509 -in certs/cert.pem -noout -dates         │
│                                                          │
│  Help/Documentation:                                     │
│    QUICK-START.md     - Fast setup                       │
│    README.md          - Main docs                        │
│    Azure-...Guide.md  - Complete guide                   │
│    WORKFLOW-DIAGRAM   - Visual guide                     │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 🔒 Security Notes

### Files to NEVER commit to Git:
- ❌ `certs/*.pem` (any PEM files)
- ❌ `certs/*.key` (private keys)
- ❌ `certs/*.p12` (PKCS12 files)
- ❌ `certs/*.pfx` (Windows certificates)
- ❌ `certs/azure-config.txt` (contains IDs)

### Files safe to commit:
- ✅ All `.md` documentation files
- ✅ All `.sh` scripts
- ✅ All `.yml` pipeline files
- ✅ `.gitignore` files

### The `certs/` directory:
- Created automatically by scripts
- Contains `.gitignore` to protect sensitive files
- Never commit entire directory
- Back up securely offline

---

## 💡 Pro Tips

1. **Keep Documentation Updated**
   - Update `certs/azure-config.txt` if you make changes
   - Document any customizations you make

2. **Bookmark These Files**
   - `QUICK-START.md` - for quick reference
   - `README.md` - for troubleshooting
   - `certs/azure-config.txt` - for your specific config

3. **Testing Strategy**
   - Use `test-cert-auth.sh` for quick CLI tests
   - Use `test-cert-auth.py` for SDK verification
   - Use `azure-pipelines-cert-test.yml` for full integration test

4. **Certificate Management**
   - Run `./generate-cert.sh` for new certificates
   - Set calendar reminder 30 days before expiry
   - Test new certificates before old ones expire

---

## 🆘 Still Confused?

### I don't know where to start
→ Open `QUICK-START.md` and follow it exactly

### I want to understand everything first
→ Read `README.md` then `Azure-Certificate-Based-Auth-Guide.md`

### Something isn't working
→ Check `README.md` Troubleshooting section

### I need to see it visually
→ Open `WORKFLOW-DIAGRAM.md`

### I just want it done
→ Run `./setup-azure-cert-auth.sh` and follow prompts

---

**Last Updated:** December 11, 2024

**Questions?** Refer to the comprehensive guide in `Azure-Certificate-Based-Auth-Guide.md`

