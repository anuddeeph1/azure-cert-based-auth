# Deploy Private AKS Cluster with Terraform Locally

This guide shows you how to deploy a **private AKS cluster** using Terraform directly from your local machine with certificate-based authentication.

---

## 🔒 What is a Private AKS Cluster?

A private AKS cluster has:
- ✅ **Private API server endpoint** (not exposed to internet)
- ✅ **No public IP** for control plane
- ✅ **Private DNS zone** for internal resolution
- ✅ **Nodes in private subnet**
- ✅ **Secure communication** within VNet

**Benefits:**
- Enhanced security (API server not publicly accessible)
- Compliance with security policies
- Reduced attack surface
- Better network isolation

---

## 📋 Prerequisites

### Required Tools
```bash
# Check if you have these installed
terraform --version  # Should be >= 1.5.0
az --version         # Azure CLI
kubectl version --client  # kubectl
```

### Install if Missing
```bash
# macOS
brew install terraform azure-cli kubectl

# Or download from:
# Terraform: https://developer.hashicorp.com/terraform/downloads
# Azure CLI: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
# kubectl: https://kubernetes.io/docs/tasks/tools/
```

---

## 🚀 Step-by-Step Deployment

### Step 1: Navigate to Terraform Directory

```bash
cd /Users/anudeepnalla/Downloads/novartis/azure-cert/novartis-azure-devops/terraform-aks-deployment/terraform
```

### Step 2: Authenticate with Azure (Certificate-Based)

```bash
# Login using your certificate
az login --service-principal \
  --username 042aea62-c886-46a1-b2f8-25c9af22a2db \
  --tenant 3d95acd6-b6ee-428e-a7a0-196120fc3c65 \
  --certificate ../../certs/service-principal-combined.pem

# Verify login
az account show

# Expected output:
# {
#   "name": "Microsoft Azure Sponsorship",
#   "user": {
#     "name": "042aea62-c886-46a1-b2f8-25c9af22a2db",
#     "type": "servicePrincipal"
#   }
# }
```

### Step 3: Review Configuration

Edit `terraform.tfvars` if needed:

```bash
# Open in your editor
open terraform.tfvars

# Or use vi/nano
vi terraform.tfvars
```

**Key settings for private cluster:**
```hcl
# Private Cluster Configuration
enable_private_cluster = true    # ← MUST be true for private cluster
private_dns_zone_id    = null    # Let Azure manage DNS

# Virtual Network (required for private cluster)
create_vnet             = true
vnet_address_space      = ["10.1.0.0/16"]
subnet_address_prefixes = ["10.1.0.0/20"]

# Cluster Configuration
cluster_name            = "aks-novartis-dev-private"
default_node_pool_min_count = 2
default_node_pool_max_count = 5
```

### Step 4: Initialize Terraform

```bash
# Initialize Terraform (downloads providers)
terraform init

# Expected output:
# Terraform has been successfully initialized!
```

### Step 5: Validate Configuration

```bash
# Validate syntax
terraform validate

# Expected output:
# Success! The configuration is valid.
```

### Step 6: Plan the Deployment

```bash
# Create execution plan
terraform plan -out=tfplan

# Review the plan output
# You should see resources to be created:
# - azurerm_resource_group
# - azurerm_virtual_network
# - azurerm_subnet
# - azurerm_kubernetes_cluster
# - azurerm_log_analytics_workspace
# etc.
```

### Step 7: Deploy the Cluster

```bash
# Apply the plan (deploy!)
terraform apply tfplan

# This will take 15-20 minutes
# You'll see progress as resources are created

# Expected final output:
# Apply complete! Resources: X added, 0 changed, 0 destroyed.
```

### Step 8: Get Cluster Credentials

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --overwrite-existing

# Verify connection
kubectl get nodes

# Expected output:
# NAME                                STATUS   ROLES   AGE     VERSION
# aks-systempool-xxxxx-vmss000000    Ready    agent   5m      v1.28.3
# aks-systempool-xxxxx-vmss000001    Ready    agent   5m      v1.28.3
```

---

## 🔍 Accessing Private AKS Cluster

Since your cluster is private, you have **3 options** to access it:

### Option 1: From Azure VM in Same VNet (Recommended)

1. **Create a Jump Box VM:**
```bash
# Create a VM in the same VNet
az vm create \
  --resource-group rg-aks-novartis-dev \
  --name vm-jumpbox \
  --image UbuntuLTS \
  --vnet-name vnet-aks-novartis-dev \
  --subnet snet-aks-nodes \
  --admin-username azureuser \
  --generate-ssh-keys

# Get VM IP
az vm show -d \
  --resource-group rg-aks-novartis-dev \
  --name vm-jumpbox \
  --query publicIps -o tsv
```

2. **SSH to Jump Box:**
```bash
ssh azureuser@<VM_PUBLIC_IP>
```

3. **Install tools on Jump Box:**
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Login and get credentials
az login
az aks get-credentials \
  --resource-group rg-aks-novartis-dev \
  --name aks-novartis-dev-private
```

### Option 2: VPN Connection to VNet

1. **Create VPN Gateway:**
```bash
# This requires additional setup
# See: https://docs.microsoft.com/en-us/azure/vpn-gateway/
```

2. **Connect via VPN, then use kubectl locally**

### Option 3: Azure Bastion (Secure)

1. **Deploy Azure Bastion:**
```bash
# Create Bastion subnet
az network vnet subnet create \
  --resource-group rg-aks-novartis-dev \
  --vnet-name vnet-aks-novartis-dev \
  --name AzureBastionSubnet \
  --address-prefixes 10.1.16.0/24

# Create Bastion (takes ~10 minutes)
az network bastion create \
  --resource-group rg-aks-novartis-dev \
  --name bastion-aks \
  --public-ip-address bastion-pip \
  --vnet-name vnet-aks-novartis-dev \
  --location "East US"
```

2. **Connect via Azure Portal → Bastion**

---

## 📊 Verify Deployment

### Check Cluster Status
```bash
# Cluster info
kubectl cluster-info

# Nodes
kubectl get nodes -o wide

# System pods
kubectl get pods -n kube-system

# All namespaces
kubectl get all --all-namespaces
```

### Check Terraform Outputs
```bash
# View all outputs
terraform output

# Specific outputs
terraform output aks_cluster_name
terraform output aks_private_fqdn
terraform output aks_is_private  # Should be: true
terraform output vnet_id
```

### Check in Azure Portal
```bash
# Open Azure Portal
open "https://portal.azure.com"

# Navigate to:
# Resource Groups → rg-aks-novartis-dev
# Click on: aks-novartis-dev-private

# Verify:
# - Networking: Should show "Private cluster: Enabled"
# - Node pools: Should show your nodes
# - Insights: Should show monitoring data
```

---

## 🧪 Test the Private Cluster

### Deploy Sample Application

```bash
# Create deployment
kubectl create deployment nginx --image=nginx:latest

# Expose as internal load balancer (private)
kubectl expose deployment nginx \
  --port=80 \
  --type=LoadBalancer \
  --name=nginx-internal

# Add annotation for internal load balancer
kubectl annotate service nginx-internal \
  service.beta.kubernetes.io/azure-load-balancer-internal="true"

# Check status
kubectl get service nginx-internal --watch

# Get internal IP
kubectl get service nginx-internal \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Test from Jump Box
```bash
# SSH to jump box
ssh azureuser@<JUMPBOX_IP>

# Test internal service
curl http://<NGINX_INTERNAL_IP>
```

---

## 🔧 Common Terraform Operations

### View Current State
```bash
terraform show
```

### Update Configuration
```bash
# Edit terraform.tfvars
vi terraform.tfvars

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Add/Remove Nodes
```bash
# Edit terraform.tfvars
default_node_pool_min_count = 3  # Change from 2 to 3

# Apply changes
terraform plan
terraform apply
```

### Destroy Cluster (Cleanup)
```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm by typing: yes
```

---

## 💰 Cost Optimization

### Private Cluster Costs

| Resource | Configuration | Monthly Cost |
|----------|---------------|--------------|
| AKS Management | Free | $0 |
| System Nodes (2x D4s_v3) | 4 vCPUs, 16GB | ~$280 |
| VNet | Standard | $0 |
| Private DNS Zone | 1 zone | ~$0.50 |
| Log Analytics | 5 GB/day | ~$15 |
| **Total** | | **~$295/month** |

### Save Money
```bash
# Stop cluster when not in use (dev/test only)
az aks stop \
  --resource-group rg-aks-novartis-dev \
  --name aks-novartis-dev-private

# Start when needed
az aks start \
  --resource-group rg-aks-novartis-dev \
  --name aks-novartis-dev-private
```

---

## 🛠️ Troubleshooting

### Cannot Access API Server
**Issue:** `Unable to connect to the server`

**Solution:** Private cluster! You must access from:
- VM in same VNet
- VPN connection
- Azure Bastion

### Terraform Apply Fails
**Issue:** `Error creating Kubernetes Cluster`

**Solution:**
```bash
# Check authentication
az account show

# Re-login if needed
az login --service-principal \
  --username 042aea62-c886-46a1-b2f8-25c9af22a2db \
  --tenant 3d95acd6-b6ee-428e-a7a0-196120fc3c65 \
  --certificate ../../certs/service-principal-combined.pem

# Check quota
az vm list-usage --location "East US" --output table
```

### Nodes Not Ready
**Issue:** Nodes stuck in "NotReady"

**Solution:**
```bash
# Check node status
kubectl describe node <node-name>

# Check system pods
kubectl get pods -n kube-system

# Common fix: Wait 5-10 minutes for initialization
```

### DNS Resolution Issues
**Issue:** Cannot resolve service names

**Solution:**
```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Restart CoreDNS if needed
kubectl rollout restart deployment coredns -n kube-system
```

---

## 📚 Additional Resources

### Azure Private AKS Documentation
- https://docs.microsoft.com/en-us/azure/aks/private-clusters

### Terraform AKS Module
- https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster

### Jump Box Setup
- https://docs.microsoft.com/en-us/azure/virtual-machines/

---

## ✅ Deployment Checklist

- [ ] Tools installed (terraform, az cli, kubectl)
- [ ] Authenticated with Azure (certificate-based)
- [ ] Reviewed terraform.tfvars configuration
- [ ] `terraform init` completed
- [ ] `terraform plan` reviewed
- [ ] `terraform apply` completed successfully
- [ ] Cluster credentials obtained
- [ ] Jump box or VPN configured for access
- [ ] Can run `kubectl get nodes`
- [ ] Sample application deployed and tested

---

## 🔐 Security Best Practices

### For Private Clusters
- ✅ Use private endpoints for all PaaS services
- ✅ Disable public network access where possible
- ✅ Use Azure Bastion instead of public IPs for VMs
- ✅ Enable network policies
- ✅ Use Azure Policy for compliance
- ✅ Implement pod security policies
- ✅ Regular security scans
- ✅ Monitor with Azure Security Center

### Network Security
- ✅ Use Network Security Groups (NSGs)
- ✅ Implement Azure Firewall if needed
- ✅ Use Application Gateway for ingress
- ✅ Enable DDoS Protection (production)

---

## 📞 Quick Reference Commands

```bash
# Initialize
terraform init

# Plan
terraform plan

# Deploy
terraform apply

# Get credentials
az aks get-credentials --resource-group rg-aks-novartis-dev --name aks-novartis-dev-private

# Check nodes
kubectl get nodes

# Deploy test app
kubectl create deployment nginx --image=nginx

# Destroy
terraform destroy
```

---

**Status:** ✅ Ready for local Terraform deployment  
**Cluster Type:** Private AKS (API server not publicly accessible)  
**Authentication:** Certificate-based (secure!)

---

**Happy deploying!** 🚀

