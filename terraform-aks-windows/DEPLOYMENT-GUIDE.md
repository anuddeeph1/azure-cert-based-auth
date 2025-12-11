# Windows AKS Cluster Deployment Guide

Complete guide for deploying a private AKS cluster with Windows node pools using certificate-based authentication.

---

## 🪟 Windows AKS Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│ PRIVATE AKS CLUSTER                                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Linux System Pool (linuxpool) - REQUIRED                          │
│  ┌───────────────────────────────────────────┐                     │
│  │ • Runs Kubernetes system components       │                     │
│  │ • CoreDNS, kube-proxy, metrics-server     │                     │
│  │ • VM: Standard_B2s (2 vCPU, 4GB)         │                     │
│  │ • Nodes: 1-2 (autoscaling)                │                     │
│  │ • OS: Linux                                │                     │
│  └───────────────────────────────────────────┘                     │
│                                                                     │
│  Windows User Pool (winpool) - YOUR APPS                           │
│  ┌───────────────────────────────────────────┐                     │
│  │ • Runs Windows containers                  │                     │
│  │ • IIS, .NET Framework, Windows Services   │                     │
│  │ • VM: Standard_B2s (or larger)            │                     │
│  │ • Nodes: 1-3 (autoscaling)                │                     │
│  │ • OS: Windows Server 2022                 │                     │
│  │ • Taint: os=windows:NoSchedule            │                     │
│  └───────────────────────────────────────────┘                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Deployment Steps

### Step 1: Authenticate
```bash
cd terraform-aks-windows/terraform

az login --service-principal \
  --username 042aea62-c886-46a1-b2f8-25c9af22a2db \
  --tenant 3d95acd6-b6ee-428e-a7a0-196120fc3c65 \
  --certificate ../../certs/service-principal-combined.pem
```

### Step 2: Review Configuration
```bash
# Edit terraform.tfvars
vi terraform.tfvars

# Key settings:
# - windows_node_pool_vm_size (check your quota!)
# - windows_node_pool_count
# - linux_node_pool_vm_size
```

### Step 3: Initialize
```bash
terraform init
```

### Step 4: Plan
```bash
terraform plan
```

### Step 5: Deploy
```bash
terraform apply
```

**Time:** 20-25 minutes (Windows nodes take longer)

---

## 📊 Configuration Details

### **Your Configuration**
```yaml
Cluster:          aks-windows-cluster
Location:         Central India
Resource Group:   rg-aks-windows
Type:             Private (no public endpoint)
Kubernetes:       1.33.5

Linux Pool:
  Name:           linuxpool
  VM:             Standard_B2s
  Nodes:          1-2

Windows Pool:
  Name:           winpool
  VM:             Standard_B2s
  Nodes:          1-3
  OS:             Windows Server 2022
  Taint:          os=windows:NoSchedule
```

---

## 🪟 Windows-Specific Features

### **Windows Admin Credentials**
```bash
# Get admin username
terraform output windows_admin_username

# Get admin password (sensitive)
terraform output windows_admin_password
```

**Use these for:**
- Troubleshooting Windows nodes
- Running commands on Windows nodes
- Emergency access

### **Windows Container Support**
```yaml
# Your Windows pods MUST include:
nodeSelector:
  kubernetes.io/os: windows

tolerations:
- key: "os"
  operator: "Equal"
  value: "windows"
  effect: "NoSchedule"
```

### **Windows Server Version**
- **OS SKU:** Windows2022
- **Base Images:** Must match (windowsservercore-ltsc2022)
- **Compatibility:** Check container base OS version

---

## 💡 Why Linux Pool is Required

**Question:** Why can't I have Windows-only cluster?

**Answer:** Kubernetes system components (CoreDNS, kube-proxy, etc.) **only run on Linux**. Therefore:

1. ✅ **Linux system pool** = Required (runs K8s components)
2. ✅ **Windows user pool** = Optional (runs your Windows apps)
3. ❌ **Windows-only cluster** = Not possible

**Best Practice:**
- Keep Linux pool small (1-2 nodes)
- Scale Windows pool based on your app needs

---

## 🔍 Verify Deployment

### Check Cluster
```bash
az aks show \
  --resource-group rg-aks-windows \
  --name aks-windows-cluster \
  --output table
```

### Check Node Pools
```bash
az aks nodepool list \
  --resource-group rg-aks-windows \
  --cluster-name aks-windows-cluster \
  --output table
```

### Check Nodes
```bash
# Get credentials first
az aks get-credentials \
  --resource-group rg-aks-windows \
  --name aks-windows-cluster

# View nodes
kubectl get nodes -o wide

# Expected:
# NAME                                STATUS   OS
# aks-linuxpool-12345-vmss000000     Ready    Linux
# aks-winpool-12345-vmss000000       Ready    Windows
```

---

## 💰 Cost Comparison

### **Linux vs Windows Nodes**

| Aspect | Linux (B2s) | Windows (B2s) |
|--------|-------------|---------------|
| vCPU | 2 | 2 |
| RAM | 4 GB | 4 GB |
| OS Disk | 30 GB (default) | 128 GB (Windows needs more) |
| Boot Time | ~2 minutes | ~5-8 minutes |
| Cost | ~$35/month | ~$35/month |

**Note:** Windows nodes typically need **larger VMs** for production:
- **Minimum:** Standard_D2s_v3 (2 vCPU, 8GB) = ~$100/month
- **Recommended:** Standard_D4s_v3 (4 vCPU, 16GB) = ~$200/month

---

## 🎓 Key Differences: Linux vs Windows AKS

| Feature | Linux AKS | Windows AKS |
|---------|-----------|-------------|
| **Node Pools** | Linux only | Linux (system) + Windows (user) |
| **Min Nodes** | 1 | 2 (1 Linux + 1 Windows) |
| **System Pool** | Can be any OS | MUST be Linux |
| **Admin Creds** | SSH keys | Username + Password |
| **Container Images** | Linux containers | Windows containers |
| **Boot Time** | Fast (~2 min) | Slower (~5-8 min) |
| **OS Disk** | 30 GB default | 128 GB minimum |
| **Cost** | Lower | Higher (need larger VMs) |

---

## 📖 Additional Resources

- **Windows Containers:** https://docs.microsoft.com/en-us/virtualization/windowscontainers/
- **AKS Windows Nodes:** https://docs.microsoft.com/en-us/azure/aks/windows-container-cli
- **.NET on Kubernetes:** https://docs.microsoft.com/en-us/dotnet/architecture/containerized-lifecycle/
- **Windows Base Images:** https://mcr.microsoft.com/

---

## ✅ Deployment Checklist

- [ ] Certificate authentication working
- [ ] Terraform installed
- [ ] Configuration reviewed (terraform.tfvars)
- [ ] Sufficient Azure quota for Windows VMs
- [ ] `terraform init` completed
- [ ] `terraform plan` reviewed
- [ ] Ready to apply!

---

**Status:** ✅ Ready for deployment  
**Cluster Type:** Private Windows AKS  
**Node Pools:** 2 (Linux system + Windows user)  
**Authentication:** Certificate-based

---

**Happy deploying Windows containers to AKS!** 🪟🚀

