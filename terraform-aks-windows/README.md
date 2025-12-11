# Terraform AKS Windows Cluster Deployment

Deploy an Azure Kubernetes Service (AKS) cluster with **Windows node pools** using Terraform and certificate-based authentication.

---

## 🪟 Windows AKS Cluster Overview

### **What Makes This Different?**

**Windows AKS clusters require:**
- ✅ **Linux system node pool** (required for Kubernetes system components)
- ✅ **Windows node pool** (for your Windows containers)
- ✅ **Windows admin credentials** (username + password)
- ✅ **Larger VMs** (Windows nodes need more resources)

**Architecture:**
```
AKS Cluster
├── Linux System Pool (linuxpool) - Required
│   └── Runs: CoreDNS, kube-proxy, metrics-server, etc.
│
└── Windows User Pool (winpool) - Your Windows apps
    └── Runs: IIS, .NET applications, Windows containers
```

---

## 📋 Prerequisites

### Required
- ✅ Azure subscription with sufficient quota
- ✅ Certificate-based authentication configured
- ✅ Terraform >= 1.5.0
- ✅ Azure CLI
- ✅ kubectl

### Windows-Specific Requirements
- ✅ **Minimum VM size:** Standard_D2s_v3 or larger for Windows nodes
- ✅ **Windows Server 2022** (default)
- ✅ **Admin password:** Auto-generated securely

---

## 🏗️ What Gets Deployed

### **Resource Group**
- Name: `rg-aks-windows`
- Location: Central India

### **Virtual Network**
- Name: `vnet-aks-windows`
- Address Space: 10.2.0.0/16
- Subnet: snet-aks-nodes (10.2.0.0/20)

### **Private AKS Cluster**
- Name: `aks-windows-cluster`
- Type: **PRIVATE** (no public endpoint)
- Kubernetes: 1.33.5

### **Node Pools**

#### **Pool 1: Linux System Pool (Required)**
```yaml
Name:        linuxpool
OS:          Linux
Purpose:     Kubernetes system components (CoreDNS, etc.)
VM Size:     Standard_B2s (2 vCPU, 4GB)
Count:       1-2 nodes (autoscaling)
Mode:        System
```

#### **Pool 2: Windows User Pool**
```yaml
Name:        winpool
OS:          Windows Server 2022
Purpose:     Your Windows/.NET applications
VM Size:     Standard_B2s (2 vCPU, 4GB) - adjust as needed
Count:       1-3 nodes (autoscaling)
Mode:        User
Taint:       os=windows:NoSchedule (Windows pods only)
```

### **Monitoring**
- Log Analytics workspace
- Container Insights enabled

---

## 🚀 Quick Start

### Step 1: Navigate to Directory
```bash
cd /Users/anudeepnalla/Downloads/novartis/azure-cert/novartis-azure-devops/terraform-aks-windows/terraform
```

### Step 2: Authenticate with Certificate
```bash
az login --service-principal \
  --username 042aea62-c886-46a1-b2f8-25c9af22a2db \
  --tenant 3d95acd6-b6ee-428e-a7a0-196120fc3c65 \
  --certificate ../../certs/service-principal-combined.pem
```

### Step 3: Initialize Terraform
```bash
terraform init
```

### Step 4: Review Configuration
```bash
# Edit if needed
vi terraform.tfvars

# Key settings:
# - windows_node_pool_vm_size (ensure you have quota!)
# - windows_node_pool_count
```

### Step 5: Plan
```bash
terraform plan
```

### Step 6: Deploy
```bash
terraform apply
```

---

## 🪟 Deploying Windows Applications

### Example: Deploy IIS Web Server

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iis-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: iis
  template:
    metadata:
      labels:
        app: iis
    spec:
      # Target Windows nodes
      nodeSelector:
        kubernetes.io/os: windows
      # Tolerate Windows taint
      tolerations:
      - key: "os"
        operator: "Equal"
        value: "windows"
        effect: "NoSchedule"
      containers:
      - name: iis
        image: mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: iis-service
spec:
  type: LoadBalancer
  selector:
    app: iis
  ports:
  - port: 80
    targetPort: 80
```

### Example: Deploy .NET Application

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dotnet-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: dotnet-app
  template:
    metadata:
      labels:
        app: dotnet-app
    spec:
      nodeSelector:
        kubernetes.io/os: windows
      tolerations:
      - key: "os"
        operator: "Equal"
        value: "windows"
        effect: "NoSchedule"
      containers:
      - name: app
        image: mcr.microsoft.com/dotnet/samples:aspnetapp
        ports:
        - containerPort: 80
```

---

## 💰 Cost Estimation

### Minimum Configuration (1 Linux + 1 Windows)
```
Linux Pool:     1 × Standard_B2s = ~$35/month
Windows Pool:   1 × Standard_B2s = ~$35/month
Log Analytics:  ~$15/month
Networking:     ~$1/month
───────────────────────────────────────
TOTAL:          ~$86/month
```

### Typical Configuration (1 Linux + 2 Windows)
```
Linux Pool:     1 × Standard_B2s = ~$35/month
Windows Pool:   2 × Standard_D4s_v3 = ~$280/month
Log Analytics:  ~$15/month
───────────────────────────────────────
TOTAL:          ~$330/month
```

**Note:** Windows nodes typically need larger VMs than Linux nodes.

---

## ⚠️ Important Windows Considerations

### **1. Linux Pool is Required**
- Windows-only clusters are NOT supported
- You MUST have at least 1 Linux system node pool
- Linux pool runs Kubernetes system components

### **2. Windows Node Requirements**
- **Minimum VM:** Standard_D2s_v3 (2 vCPU, 8GB)
- **Recommended:** Standard_D4s_v3 or larger
- **OS Disk:** At least 128 GB
- **Windows Server:** 2022 (default)

### **3. Node Taints**
Windows nodes have taint: `os=windows:NoSchedule`

**This means:**
- Linux pods won't schedule on Windows nodes
- Windows pods must tolerate this taint

### **4. Container Images**
- **Must use Windows containers** for Windows nodes
- Base images: `mcr.microsoft.com/windows/servercore` or `mcr.microsoft.com/windows/nanoserver`
- Linux containers won't run on Windows nodes!

---

## 🔒 Security Features

### **Authentication**
- ✅ Certificate-based (your existing setup)
- ✅ No secrets in code
- ✅ Managed identities for cluster components

### **Network Security**
- ✅ Private cluster (no public API endpoint)
- ✅ Azure CNI networking
- ✅ Network policies enabled
- ✅ Private VNet

### **RBAC**
- ✅ Azure AD integration
- ✅ Azure RBAC enabled
- ✅ Managed Azure AD integration

### **Windows Security**
- ✅ Auto-generated strong password
- ✅ Password stored in Terraform state (encrypted)
- ✅ Windows Server 2022 (latest)

---

## 🧪 Testing Windows Workloads

### Get Windows Admin Password
```bash
# After deployment
terraform output windows_admin_password
```

### Deploy Test IIS App
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: iis-test
spec:
  nodeSelector:
    kubernetes.io/os: windows
  tolerations:
  - key: "os"
    operator: "Equal"
    value: "windows"
    effect: "NoSchedule"
  containers:
  - name: iis
    image: mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022
EOF

# Check status
kubectl get pod iis-test --watch

# When running, port-forward to test
kubectl port-forward pod/iis-test 8080:80

# Open browser: http://localhost:8080
```

---

## 🔧 Common Operations

### View Node Pools
```bash
kubectl get nodes -o wide

# Expected:
# NAME                              STATUS   OS      
# aks-linuxpool-xxxxx-vmss000000   Ready    Linux
# aks-winpool-xxxxx-vmss000000     Ready    Windows
```

### Scale Windows Pool
```bash
az aks nodepool scale \
  --resource-group rg-aks-windows \
  --cluster-name aks-windows-cluster \
  --name winpool \
  --node-count 3
```

### Add Another Windows Pool
```bash
az aks nodepool add \
  --resource-group rg-aks-windows \
  --cluster-name aks-windows-cluster \
  --name winpool2 \
  --node-count 2 \
  --node-vm-size Standard_D4s_v3 \
  --os-type Windows \
  --os-sku Windows2022 \
  --node-taints os=windows:NoSchedule
```

---

## 📚 Windows Container Resources

### **Official Windows Container Images**
- https://mcr.microsoft.com/windows/servercore
- https://mcr.microsoft.com/windows/nanoserver
- https://mcr.microsoft.com/dotnet/aspnet
- https://mcr.microsoft.com/windows/servercore/iis

### **Documentation**
- Windows Containers: https://docs.microsoft.com/en-us/virtualization/windowscontainers/
- AKS Windows: https://docs.microsoft.com/en-us/azure/aks/windows-container-cli

---

## ⚠️ Troubleshooting

### Windows Pod Won't Schedule
**Error:** `0/X nodes are available: X node(s) didn't match Pod's node affinity/selector`

**Solution:**
```yaml
# Add to your pod spec:
nodeSelector:
  kubernetes.io/os: windows
tolerations:
- key: "os"
  operator: "Equal"
  value: "windows"
  effect: "NoSchedule"
```

### Windows Node Not Ready
```bash
# Check node status
kubectl describe node <windows-node-name>

# Common issue: Windows nodes take longer to start (5-10 minutes)
```

### Cannot Access Windows Node
```bash
# Windows admin password
terraform output windows_admin_password

# RDP access requires additional setup (not recommended for AKS)
# Use kubectl exec instead:
kubectl exec -it <windows-pod> -- powershell
```

---

## 🎯 Next Steps

After deployment:
1. ✅ Get Windows admin password: `terraform output windows_admin_password`
2. ✅ Deploy test IIS application
3. ✅ Configure Windows-specific monitoring
4. ✅ Deploy your .NET applications
5. ✅ Set up ingress for Windows services

---

**Status:** ✅ Ready for deployment  
**Cluster Type:** Private AKS with Windows support  
**Node Pools:** 2 (1 Linux + 1 Windows)  
**Authentication:** Certificate-based

---

**Deploy with:** `terraform apply`

