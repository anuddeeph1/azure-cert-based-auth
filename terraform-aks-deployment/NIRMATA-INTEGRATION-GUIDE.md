# Nirmata Integration for AKS Cluster

This guide shows you how to integrate your AKS cluster with Nirmata for Kubernetes management, policy enforcement, and security.

---

## 🎯 What is Nirmata?

Nirmata provides:
- ✅ **Kubernetes Policy Management** (Kyverno-based)
- ✅ **Security & Compliance** enforcement
- ✅ **Multi-cluster Management**
- ✅ **Cost Management & Optimization**
- ✅ **Application Lifecycle Management**

---

## 📋 Prerequisites

### Required
- ✅ AKS cluster deployed (aks-novartis-dev)
- ✅ Nirmata account (https://nirmata.io)
- ✅ Nirmata API token
- ✅ Certificate-based authentication to Azure
- ✅ kubectl access to the cluster

---

## 🚀 Setup Steps

### Step 1: Get Nirmata API Token

1. **Login to Nirmata:**
   ```
   https://nirmata.io
   ```

2. **Navigate to API Keys:**
   - Click your profile (top right)
   - Settings → API Keys
   - Or direct: https://nirmata.io/settings/api-keys

3. **Create New API Key:**
   - Click "Create API Key"
   - Name: `terraform-aks-integration`
   - Permissions: Admin or Cluster Admin
   - Copy the token (you'll need it next)

---

### Step 2: Configure Nirmata Variables

Edit `terraform.tfvars` and add:

```hcl
# Enable Nirmata integration
enable_nirmata = true

# Nirmata API credentials
nirmata_token        = "YOUR_NIRMATA_API_TOKEN"  # Paste your token here
nirmata_url          = "https://nirmata.io"

# Cluster registration
nirmata_cluster_name = "aks-novartis-dev"
nirmata_cluster_type = "default-add-ons"
```

**Or copy from example:**
```bash
cd terraform
cat nirmata.tfvars.example >> terraform.tfvars
# Then edit terraform.tfvars and add your token
```

---

### Step 3: Install Nirmata Provider

The Nirmata provider will be installed automatically, but you can also install it manually:

```bash
terraform init -upgrade
```

---

### Step 4: Deploy Nirmata Integration

```bash
cd terraform

# Plan (review what will be added)
terraform plan

# Apply (this will register cluster and install Nirmata controllers)
terraform apply
```

**Time:** 5-10 minutes

---

## 📊 What Gets Deployed

### **Nirmata Components**

1. **Nirmata Namespace**
   - Namespace: `nirmata`
   - Purpose: Houses Nirmata controllers

2. **Nirmata Kube Controller**
   - Deployment: `nirmata-kube-controller`
   - Purpose: Manages communication with Nirmata platform
   - Replicas: 1-3 (auto-scaled)

3. **Service Accounts**
   - `nirmata-admin-sa`
   - `nirmata-controller-sa`
   - Purpose: RBAC for Nirmata components

4. **CRDs (Custom Resource Definitions)**
   - PolicyReports
   - ClusterPolicyReports
   - Nirmata-specific CRDs

5. **RBAC (Roles & Bindings)**
   - ClusterRole: `nirmata-admin`
   - ClusterRoleBinding
   - Purpose: Permissions for Nirmata

---

## 🔐 How It Works with Certificate Auth

```
Your Certificate Authentication
        ↓
Azure CLI (az login --certificate)
        ↓
Terraform reads Azure CLI credentials
        ↓
Creates AKS cluster
        ↓
Registers cluster with Nirmata API
        ↓
Downloads Nirmata controller manifests
        ↓
Applies manifests to AKS using kubectl
        ↓
Nirmata controllers connect to Nirmata platform
```

**Key Points:**
- ✅ Uses your certificate-based authentication
- ✅ No additional credentials needed
- ✅ Secure integration
- ✅ Nirmata token only used for API calls

---

## 🔍 Verify Nirmata Installation

### Check Nirmata Namespace
```bash
kubectl get namespace nirmata
```

### Check Nirmata Pods
```bash
kubectl get pods -n nirmata

# Expected:
# NAME                                      READY   STATUS
# nirmata-kube-controller-xxxxx            1/1     Running
```

### Check Nirmata Services
```bash
kubectl get svc -n nirmata
```

### Check Nirmata Logs
```bash
kubectl logs -n nirmata -l app=nirmata-kube-controller --tail=50
```

---

## 🌐 Accessing Nirmata Dashboard

1. **Login to Nirmata:**
   ```
   https://nirmata.io
   ```

2. **View Your Cluster:**
   - Navigate to: Clusters
   - Find: `aks-novartis-dev`
   - Status should show: ✅ Connected

3. **View Cluster Details:**
   - Click on cluster name
   - View: Nodes, Workloads, Policies, Compliance

---

## 📊 Nirmata Features for AKS

### **1. Policy Management**
- Define and enforce Kubernetes policies
- Based on Kyverno (CNCF project)
- Policy violations and reports

### **2. Security & Compliance**
- CIS Kubernetes Benchmarks
- Pod Security Standards
- Network policies
- Image scanning integration

### **3. Cost Management**
- Resource usage tracking
- Cost allocation by namespace/team
- Optimization recommendations

### **4. Multi-Cluster Management**
- Manage multiple AKS clusters
- Unified dashboard
- Cross-cluster policies

---

## 🔧 Nirmata Configuration

### **Adjust Controller Resources**

If you need to adjust Nirmata controller resources, you can modify the deployment after installation:

```bash
kubectl edit deployment nirmata-kube-controller -n nirmata

# Modify resources:
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "200m"
```

### **Enable Additional Features**

In Nirmata dashboard:
1. Go to Cluster → Settings
2. Enable desired features:
   - Policy enforcement
   - Image scanning
   - Cost management
   - Backup/DR

---

## ⚠️ Private Cluster Considerations

Since your AKS cluster is **PRIVATE**, the Nirmata controller deployment works differently:

### **How Nirmata Accesses Private Cluster**

```
Terraform (your laptop)
    ↓
Applies Nirmata manifests via kubectl
    ↓
Nirmata controllers run INSIDE the cluster
    ↓
Controllers make OUTBOUND connections to Nirmata platform
    ↓
Nirmata platform receives cluster data
```

**Key Points:**
- ✅ Nirmata doesn't need inbound access to your private cluster
- ✅ Controllers make outbound HTTPS calls
- ✅ Your private API server stays private
- ✅ Secure architecture

---

## 🆘 Troubleshooting

### Nirmata Controller Not Starting

```bash
# Check pod status
kubectl get pods -n nirmata

# View logs
kubectl logs -n nirmata -l app=nirmata-kube-controller

# Describe pod
kubectl describe pod -n nirmata -l app=nirmata-kube-controller
```

### Cluster Not Showing in Nirmata Dashboard

**Common causes:**
1. Nirmata token invalid/expired
2. Outbound connectivity blocked
3. Controller not running

**Solutions:**
```bash
# Verify token is correct
terraform output nirmata_cluster_id

# Check controller logs
kubectl logs -n nirmata -l app=nirmata-kube-controller --tail=100

# Restart controller
kubectl rollout restart deployment nirmata-kube-controller -n nirmata
```

### kyverno-operator Issues

The configuration automatically removes `kyverno-operator` deployment as it can conflict. If you see issues:

```bash
# Check if it exists
kubectl get deployment kyverno-operator --all-namespaces

# Delete if present
kubectl delete deployment kyverno-operator -n <namespace> --ignore-not-found
```

---

## 🎯 Quick Reference

### Enable Nirmata
```hcl
# In terraform.tfvars:
enable_nirmata = true
nirmata_token = "your-token-here"
```

### Deploy
```bash
terraform apply
```

### Verify
```bash
kubectl get pods -n nirmata
```

### Access Dashboard
```
https://nirmata.io → Clusters → aks-novartis-dev
```

---

## 💡 Best Practices

### **Security**
- ✅ Store Nirmata token securely (use Terraform variables)
- ✅ Rotate API tokens regularly
- ✅ Use least-privilege API tokens
- ✅ Monitor Nirmata controller logs

### **Operations**
- ✅ Keep Nirmata controllers updated
- ✅ Monitor controller resource usage
- ✅ Review policy violations regularly
- ✅ Set up alerts in Nirmata dashboard

### **Cost**
- ✅ Monitor via Nirmata cost dashboard
- ✅ Set budget alerts
- ✅ Review optimization recommendations

---

## 📚 Additional Resources

- **Nirmata Documentation:** https://docs.nirmata.io
- **Nirmata AKS Guide:** https://docs.nirmata.io/kubernetes/aks
- **Kyverno Policies:** https://kyverno.io/policies/
- **Support:** support@nirmata.com

---

## ✅ Integration Checklist

- [ ] Nirmata account created
- [ ] API token generated
- [ ] Token added to terraform.tfvars
- [ ] enable_nirmata = true set
- [ ] terraform init completed
- [ ] terraform plan reviewed
- [ ] terraform apply completed
- [ ] Nirmata pods running
- [ ] Cluster appears in Nirmata dashboard
- [ ] Policies configured in Nirmata

---

**Status:** ✅ Ready for Nirmata integration  
**Configuration:** nirmata.tf + nirmata-variables.tf  
**Example:** nirmata.tfvars.example  
**Guide:** This file

---

**Happy managing your AKS cluster with Nirmata!** 🚀

