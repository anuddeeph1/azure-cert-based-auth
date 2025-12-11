# 🚀 Start Deployment - Private AKS with 2 Node Pools

**You're ready to deploy!** Everything is configured for a **private AKS cluster** with **2 node pools** using **certificate-based authentication**.

---

## ✅ What's Configured

### Cluster Configuration
```yaml
Type:               Private AKS (no public endpoint)
Location:           Central India
Resource Group:     rg-anudeep
Cluster Name:       aks-novartis-dev
Kubernetes:         1.28.3
Virtual Network:    vnet-aks-novartis-dev (10.1.0.0/16)
Authentication:     Certificate-based (your service principal)
```

### Node Pool 1: System Pool
```yaml
Name:               systempool
Purpose:            Kubernetes system components
VM Size:            Standard_D4s_v3 (4 vCPUs, 16 GB RAM)
Nodes:              2-5 (autoscaling)
Cost:               ~$280-700/month
```

### Node Pool 2: User Pool
```yaml
Name:               userpool  
Purpose:            Your application workloads
VM Size:            Standard_D8s_v3 (8 vCPUs, 32 GB RAM)
Nodes:              2-10 (autoscaling)
Cost:               ~$560-2800/month
```

---

## 🎯 Deploy in 5 Commands

```bash
# 1. Go to terraform folder
cd /Users/anudeepnalla/Downloads/novartis/azure-cert/novartis-azure-devops/terraform-aks-deployment/terraform

# 2. Login with certificate
az login --service-principal \
  --username 042aea62-c886-46a1-b2f8-25c9af22a2db \
  --tenant 3d95acd6-b6ee-428e-a7a0-196120fc3c65 \
  --certificate ../../certs/service-principal-combined.pem

# 3. Initialize
terraform init

# 4. Plan (review what will be created)
terraform plan

# 5. Deploy (type "yes" when prompted)
terraform apply
```

**Time:** 15-20 minutes ⏱️

---

## 🤖 OR: Use Automated Script

```bash
cd /Users/anudeepnalla/Downloads/novartis/azure-cert/novartis-azure-devops/terraform-aks-deployment

./deploy-aks.sh
```

The script:
- ✅ Checks prerequisites
- ✅ Authenticates with certificate
- ✅ Runs terraform init/plan/apply
- ✅ Gets AKS credentials
- ✅ Verifies deployment

---

## 🔐 Understanding Certificate Authentication

### Your Certificate Chain

```
Local Certificate File (certs/service-principal-combined.pem)
    ↓
Azure CLI Login (az login --certificate)
    ↓
Access Token Generated (valid 1 hour)
    ↓  
Token Stored (~/.azure/msal_token_cache.json)
    ↓
Terraform Reads Token from Azure CLI
    ↓
Terraform Makes API Calls with Token
    ↓
Azure Validates Token & Permissions
    ↓
Resources Created (AKS, Node Pools, VNet, etc.)
```

### Why No Credentials in Terraform Code?

Look at `providers.tf`:
```hcl
provider "azurerm" {
  features { }
  
  # Notice: NO client_id, client_secret, or certificate here!
  # Terraform automatically uses Azure CLI credentials
}
```

**This is secure because:**
- ✅ No secrets in code
- ✅ Credentials managed by Azure CLI
- ✅ Certificate stays on your machine
- ✅ Token automatically refreshed

**Read more:** `HOW-CERTIFICATE-AUTH-WORKS.md`

---

## 📊 What Will Be Created

Running `terraform apply` will create approximately **8-10 resources**:

```
Plan: 8 to add, 0 to change, 0 to destroy.

Resources to be created:
  1. azurerm_resource_group.aks
  2. azurerm_virtual_network.aks[0]
  3. azurerm_subnet.aks[0]
  4. azurerm_log_analytics_workspace.aks[0]
  5. azurerm_kubernetes_cluster.aks
     ├── default_node_pool (systempool) ← Node Pool 1
     └── identity (system-assigned)
  6. azurerm_kubernetes_cluster_node_pool.user[0]  ← Node Pool 2
```

---

## 🔒 After Deployment: Accessing Private Cluster

Your cluster will be **PRIVATE** - no public API endpoint!

### Option 1: Create Jump Box (Recommended)

```bash
# After AKS is deployed, create a VM in the same VNet
az vm create \
  --resource-group rg-anudeep \
  --name vm-jumpbox \
  --image Ubuntu2204 \
  --vnet-name vnet-aks-novartis-dev \
  --subnet snet-aks-nodes \
  --admin-username azureuser \
  --generate-ssh-keys \
  --size Standard_B2s

# Get VM IP
VM_IP=$(az vm show -d --resource-group rg-anudeep --name vm-jumpbox --query publicIps -o tsv)

# SSH to jumpbox
ssh azureuser@$VM_IP

# On jumpbox: Install tools and get credentials
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo az aks install-cli
az login
az aks get-credentials --resource-group rg-anudeep --name aks-novartis-dev

# Now you can use kubectl
kubectl get nodes
```

### Option 2: Run Commands via Azure CLI

Even from your local machine, you can run commands through Azure CLI:

```bash
# Run command on AKS
az aks command invoke \
  --resource-group rg-anudeep \
  --name aks-novartis-dev \
  --command "kubectl get nodes"

# Deploy application
az aks command invoke \
  --resource-group rg-anudeep \
  --name aks-novartis-dev \
  --command "kubectl apply -f -" \
  --file deployment.yaml
```

---

## 🧪 Verify Deployment

### Check Terraform Outputs

```bash
cd terraform

# View all outputs
terraform output

# Specific outputs
terraform output aks_cluster_name
terraform output aks_is_private        # Should be: true
terraform output aks_private_fqdn      # Private FQDN
terraform output vnet_id               # Your VNet
```

### Check Node Pools

```bash
# List node pools
az aks nodepool list \
  --resource-group rg-anudeep \
  --cluster-name aks-novartis-dev \
  --output table

# Expected output:
# Name        OsType    VmSize           Count    MaxPods
# ----------  --------  ---------------  -------  ---------
# systempool  Linux     Standard_D4s_v3  2        30
# userpool    Linux     Standard_D8s_v3  2        30
```

### Check Cluster Status

```bash
# Show cluster details
az aks show \
  --resource-group rg-anudeep \
  --name aks-novartis-dev \
  --output table

# Check if private
az aks show \
  --resource-group rg-anudeep \
  --name aks-novartis-dev \
  --query "apiServerAccessProfile.enablePrivateCluster"
  
# Output: true
```

---

## 💡 Understanding Your Configuration

### File: `terraform.tfvars`

```hcl
# What you changed:
location = "centralindia"              # Your region
resource_group_name = "rg-anudeep"     # Existing RG
enable_user_node_pool = true           # ← Creates 2nd node pool!
enable_private_cluster = true          # ← Makes cluster private!

# Node Pool 1 (System) config:
default_node_pool_vm_size = "Standard_D4s_v3"
default_node_pool_min_count = 2
default_node_pool_max_count = 5

# Node Pool 2 (User) config:
user_node_pool_vm_size = "Standard_D8s_v3"
user_node_pool_count = 2  # Can scale to 10
```

### File: `main.tf`

This defines:
- **Resource group** (`azurerm_resource_group`)
- **Virtual network** for private cluster
- **AKS cluster** with private endpoint
- **System node pool** (built into cluster)
- **User node pool** (separate resource)
- **Log Analytics** for monitoring

### File: `providers.tf`

```hcl
provider "azurerm" {
  features { }
  
  # Uses Azure CLI credentials automatically
  # No need to specify certificate here!
}
```

---

## 🎯 Deploy Now!

**Ready to create your private AKS cluster with 2 node pools?**

### Quick Start:
```bash
cd terraform-aks-deployment
./deploy-aks.sh
```

### Manual:
```bash
cd terraform-aks-deployment/terraform
az login --service-principal --certificate ../../certs/service-principal-combined.pem --username 042aea62-c886-46a1-b2f8-25c9af22a2db --tenant 3d95acd6-b6ee-428e-a7a0-196120fc3c65
terraform init
terraform plan
terraform apply
```

---

## ✅ After Deployment

1. **Outputs will show:**
   - Cluster name
   - Private FQDN
   - VNet ID
   - Connection command

2. **Create Jump Box** to access the private cluster

3. **Deploy your applications** to the user node pool

4. **Monitor** via Azure Portal or Log Analytics

---

## 📚 Documentation

- **Deployment Guide:** `TERRAFORM-LOCAL-DEPLOYMENT.md`
- **How Auth Works:** `HOW-CERTIFICATE-AUTH-WORKS.md`
- **Complete Docs:** `README.md`

---

**Status:** ✅ Ready to deploy  
**Configuration:** ✅ Private cluster with 2 node pools  
**Authentication:** ✅ Certificate-based  
**Time to Deploy:** ⏱️ 15-20 minutes

**Let's do this!** 🚀

