# 🚀 Quick Start - Deploy AKS with Terraform

**Time to Deploy:** 15-20 minutes

---

## ✅ Prerequisites Check

Before you start, verify:
- [x] Certificate-based service connection created (`azure-cert-sp-connection`)
- [x] Service connection working (you tested it!)
- [x] Access to Azure DevOps: https://dev.azure.com/nirmata/anudeep
- [x] Project code in Git repository

---

## 📋 Step-by-Step Deployment

### Step 1: Review Configuration (2 minutes)

Edit `terraform/terraform.tfvars` if needed:

```bash
# Open the file
cd terraform-aks-deployment/terraform
open terraform.tfvars
```

**Key settings to review:**
- `cluster_name` - Name of your AKS cluster
- `location` - Azure region
- `default_node_pool_vm_size` - VM size for nodes
- `default_node_pool_min_count` - Minimum nodes (cost!)

---

### Step 2: Commit to Git (3 minutes)

```bash
# From the project root
cd /Users/anudeepnalla/Downloads/novartis/azure-cert/novartis-azure-devops

# Add the new folder
git add terraform-aks-deployment/

# Commit
git commit -m "Add Terraform AKS deployment with certificate auth"

# Push to Azure DevOps
git push origin main
```

---

### Step 3: Create Pipeline in Azure DevOps (5 minutes)

1. **Go to Pipelines:**
   ```
   https://dev.azure.com/nirmata/anudeep/_build
   ```

2. **Click "New pipeline"**

3. **Select your repository source:**
   - Azure Repos Git
   - Select your repository

4. **Configure your pipeline:**
   - Select: **"Existing Azure Pipelines YAML file"**
   - Branch: `main`
   - Path: `/terraform-aks-deployment/pipelines/azure-pipelines-terraform-aks.yml`

5. **Review and click "Run"**

---

### Step 4: Watch the Pipeline Run (15-20 minutes)

The pipeline will:

```
Stage 1: Validate & Plan (2-3 minutes)
  ✓ Install Terraform
  ✓ Initialize configuration
  ✓ Validate syntax
  ✓ Create execution plan

Stage 2: Deploy AKS (15-18 minutes)
  ✓ Apply Terraform plan
  ✓ Create AKS cluster
  ✓ Configure node pools
  ✓ Set up networking
  ✓ Enable monitoring
  ✓ Get kubectl credentials
  ✓ Verify deployment

Stage 3: Post-Deployment (1 minute)
  ✓ Generate documentation
  ✓ Publish artifacts
```

---

### Step 5: Access Your Cluster (2 minutes)

After successful deployment, connect to your cluster:

```bash
# Get credentials
az aks get-credentials \
  --resource-group rg-aks-novartis-dev \
  --name aks-novartis-dev \
  --overwrite-existing

# Verify connection
kubectl get nodes

# Expected output:
# NAME                                STATUS   ROLES   AGE   VERSION
# aks-systempool-12345678-vmss000000  Ready    agent   5m    v1.28.3
# aks-systempool-12345678-vmss000001  Ready    agent   5m    v1.28.3
```

---

## 🎉 Success! What Now?

### Deploy a Test Application

```bash
# Deploy nginx
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Wait for external IP
kubectl get service nginx --watch

# Test the service
curl http://<EXTERNAL-IP>
```

### View Cluster in Azure Portal

```
https://portal.azure.com
→ Search for "aks-novartis-dev"
→ Click on the cluster
→ Explore: Nodes, Networking, Monitoring
```

### View Kubernetes Dashboard

```bash
# Start kubectl proxy
kubectl proxy

# Access dashboard
open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## 🔧 Quick Commands Reference

### Cluster Info
```bash
# Show cluster details
kubectl cluster-info

# Get all nodes
kubectl get nodes -o wide

# View all pods
kubectl get pods --all-namespaces
```

### Scaling
```bash
# Scale deployment
kubectl scale deployment nginx --replicas=3

# Check pod status
kubectl get pods
```

### Monitoring
```bash
# View events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# View logs
kubectl logs <pod-name>

# Describe resource
kubectl describe pod <pod-name>
```

---

## 💡 Configuration Options

### Small Cluster (Dev/Test)
```hcl
default_node_pool_vm_size   = "Standard_D2s_v3"  # 2 vCPUs, 8GB
default_node_pool_min_count = 1
default_node_pool_max_count = 3
```
**Cost:** ~$140/month

### Medium Cluster (Staging)
```hcl
default_node_pool_vm_size   = "Standard_D4s_v3"  # 4 vCPUs, 16GB
default_node_pool_min_count = 2
default_node_pool_max_count = 5
```
**Cost:** ~$280/month

### Large Cluster (Production)
```hcl
default_node_pool_vm_size   = "Standard_D8s_v3"  # 8 vCPUs, 32GB
default_node_pool_min_count = 3
default_node_pool_max_count = 10
enable_user_node_pool       = true
```
**Cost:** ~$800/month

---

## ⚠️ Important Notes

### First-Time Deployment
- Cluster creation takes 15-20 minutes
- Be patient! AKS provisioning is complex
- Check pipeline logs if issues occur

### Certificate Authentication
- ✅ Your pipeline uses certificate auth (secure!)
- ✅ No secrets stored in code
- ⏰ Certificate expires: Dec 11, 2026

### Cost Management
- 💰 AKS management is FREE
- 💰 You pay for VMs and storage
- 💰 Use autoscaling to reduce costs
- 💰 Stop cluster when not in use (dev/test)

---

## 🆘 Troubleshooting

### Pipeline Fails at "Terraform Init"
```bash
# Check service connection
# Go to Azure DevOps → Service Connections
# Verify: azure-cert-sp-connection is "Ready"
```

### Pipeline Fails at "Terraform Apply"
```bash
# Common causes:
# 1. Insufficient permissions → Verify Contributor role
# 2. Region capacity → Try different region
# 3. Quota limits → Check subscription quotas
```

### Cannot Connect to Cluster
```bash
# Re-get credentials
az aks get-credentials \
  --resource-group rg-aks-novartis-dev \
  --name aks-novartis-dev \
  --overwrite-existing

# Verify authentication
kubectl cluster-info
```

---

## 📚 Next Steps

After successful deployment:

1. ✅ **Test cluster** with sample app
2. ✅ **Configure Ingress** (nginx or App Gateway)
3. ✅ **Set up monitoring** dashboards
4. ✅ **Deploy your applications**
5. ✅ **Set up CI/CD** for app deployments

---

## 🎯 Quick Reference

| What | Command/Link |
|------|--------------|
| **Azure DevOps** | https://dev.azure.com/nirmata/anudeep |
| **Service Connection** | azure-cert-sp-connection |
| **Get Credentials** | `az aks get-credentials --resource-group rg-aks-novartis-dev --name aks-novartis-dev` |
| **View Nodes** | `kubectl get nodes` |
| **View Pods** | `kubectl get pods -A` |
| **Cluster Info** | `kubectl cluster-info` |

---

**Ready to deploy?** Follow the steps above and you'll have your AKS cluster running in ~20 minutes! 🚀

