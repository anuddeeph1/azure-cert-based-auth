# Nirmata Integration for Windows AKS Cluster

Guide for integrating your Windows AKS cluster with Nirmata for policy management and security.

---

## 🪟 Windows AKS + Nirmata

### **What This Adds:**
- ✅ Policy management for Windows workloads
- ✅ Security compliance for Windows containers
- ✅ Monitoring for Windows nodes
- ✅ Unified management across Linux and Windows

---

## 🚀 Quick Setup

### Step 1: Configure Nirmata in terraform.tfvars

Add to `terraform/terraform.tfvars`:

```hcl
# Nirmata Configuration
enable_nirmata = true
nirmata_token = "GU4XLFKtCP1w8v3R3rv30qD6PLEOR7dbtYtM2yck5AzTfJOGSnmxTH3X0DVeEF1xSyr8qgmtbCjw9ki8ZKMJOw=="
nirmata_url = "https://nirmata.io"
nirmata_cluster_name = "aks-win-cluster"
nirmata_cluster_type = "default-add-ons"
```

### Step 2: Initialize with Nirmata Provider

```bash
cd terraform
terraform init -upgrade
```

### Step 3: Plan and Apply

```bash
terraform plan
terraform apply
```

---

## ⚠️ Private Cluster Limitation

Your Windows cluster is **PRIVATE**, so Nirmata controller deployment from your laptop won't work directly.

### **Solution: Deploy via az aks command invoke**

After Terraform registers the cluster:

```bash
# Get the controller YAMLs folder from output
YAMLS_FOLDER=$(terraform output -raw nirmata_controller_yamls_folder)

# Deploy each manifest via command invoke
for manifest in $YAMLS_FOLDER/temp-*.yaml; do
  az aks command invoke \
    --resource-group rg-anudeep \
    --name aks-win-cluster \
    --command "kubectl apply -f -" \
    --file "$manifest"
done
```

---

## 🪟 Windows-Specific Nirmata Features

### **Windows Policy Management**
- Windows container policies
- Windows Server compliance checks
- Windows-specific security policies
- Image validation for Windows containers

### **Windows Node Monitoring**
- Windows node metrics
- Windows container monitoring
- Resource usage tracking
- Performance insights

---

## 📊 Configuration Details

```yaml
Cluster Type:       Windows AKS (aks-win-cluster)
Nirmata Name:       aks-win-cluster
Cluster Type:       default-add-ons
Node Pools:
  - linuxpool:      Nirmata controller runs here
  - win01:          Monitored by Nirmata

Nirmata Controller:
  Namespace:        nirmata
  Runs on:          Linux nodes (linuxpool)
  Monitors:         Both Linux and Windows nodes
```

---

## ✅ Verify Integration

### Check Nirmata Registration

```bash
# View Nirmata cluster ID
terraform output nirmata_cluster_id

# Check in Nirmata Dashboard
open https://nirmata.io
# Navigate to: Clusters → aks-win-cluster
```

### Check Nirmata Pods (after manual deployment)

```bash
# Via command invoke
az aks command invoke \
  --resource-group rg-anudeep \
  --name aks-win-cluster \
  --command "kubectl get pods -n nirmata"
```

---

## 💡 Key Points

### **Nirmata Controller Location**
The Nirmata controller will run on **Linux nodes** (linuxpool), but will monitor **both** Linux and Windows nodes.

### **Windows Workload Policies**
You can create Windows-specific policies in Nirmata that apply only to Windows pods.

### **Resource Usage**
Nirmata controller: ~250m CPU, 200-500Mi RAM (runs on Linux pool)

---

## 🎯 Complete Setup Checklist

- [ ] Nirmata token added to terraform.tfvars
- [ ] enable_nirmata = true
- [ ] terraform init -upgrade completed
- [ ] terraform apply completed
- [ ] Cluster registered in Nirmata ✅
- [ ] Controller YAMLs deployed (manually via command invoke)
- [ ] Nirmata pods running
- [ ] Cluster visible in Nirmata dashboard

---

**Status:** ✅ Configuration added  
**Ready to enable:** Yes (add token and set enable_nirmata = true)

---

**See also:** `../terraform-aks-deployment/NIRMATA-INTEGRATION-GUIDE.md` for general Nirmata documentation

