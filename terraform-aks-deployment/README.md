# Terraform AKS Deployment with Certificate-Based Authentication

This project deploys an Azure Kubernetes Service (AKS) cluster using Terraform and Azure DevOps pipelines with certificate-based authentication.

---

## 📋 Prerequisites

### Azure Requirements
- ✅ Azure subscription (Microsoft Azure Sponsorship)
- ✅ Azure service principal with certificate authentication (already configured!)
- ✅ Azure DevOps service connection: `azure-cert-sp-connection`
- ✅ Contributor permissions on subscription

### Tools Required (for local development)
- Terraform >= 1.5.0
- Azure CLI
- kubectl
- Git

---

## 📁 Project Structure

```
terraform-aks-deployment/
├── terraform/
│   ├── providers.tf          # Provider configuration
│   ├── main.tf                # AKS cluster resources
│   ├── variables.tf           # Variable definitions
│   ├── outputs.tf             # Output definitions
│   └── terraform.tfvars       # Variable values (customize this!)
├── pipelines/
│   └── azure-pipelines-terraform-aks.yml  # Azure DevOps pipeline
├── docs/
│   ├── DEPLOYMENT-GUIDE.md    # Detailed deployment guide
│   └── TROUBLESHOOTING.md     # Common issues and solutions
└── README.md                  # This file
```

---

## 🚀 Quick Start

### Option 1: Deploy via Azure DevOps Pipeline (Recommended)

1. **Commit this project to your Azure DevOps repository:**
   ```bash
   cd /Users/anudeepnalla/Downloads/novartis/azure-cert/novartis-azure-devops
   git add terraform-aks-deployment/
   git commit -m "Add Terraform AKS deployment"
   git push
   ```

2. **Create pipeline in Azure DevOps:**
   - Go to: https://dev.azure.com/nirmata/anudeep/_build
   - Click "New pipeline"
   - Select your repository
   - Select "Existing Azure Pipelines YAML file"
   - Path: `/terraform-aks-deployment/pipelines/azure-pipelines-terraform-aks.yml`
   - Click "Run"

3. **Pipeline will:**
   - ✅ Validate Terraform configuration
   - ✅ Create execution plan
   - ✅ Deploy AKS cluster (on main branch)
   - ✅ Configure kubectl access
   - ✅ Verify deployment

### Option 2: Deploy Locally (for testing)

1. **Navigate to Terraform directory:**
   ```bash
   cd terraform-aks-deployment/terraform
   ```

2. **Login to Azure with certificate:**
   ```bash
   az login --service-principal \
     --username 042aea62-c886-46a1-b2f8-25c9af22a2db \
     --tenant 3d95acd6-b6ee-428e-a7a0-196120fc3c65 \
     --certificate ../../certs/service-principal-combined.pem
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the plan:**
   ```bash
   terraform plan
   ```

5. **Apply (deploy):**
   ```bash
   terraform apply
   ```

6. **Get AKS credentials:**
   ```bash
   az aks get-credentials \
     --resource-group $(terraform output -raw resource_group_name) \
     --name $(terraform output -raw aks_cluster_name)
   ```

7. **Verify:**
   ```bash
   kubectl get nodes
   ```

---

## ⚙️ Configuration

### Customize Your AKS Cluster

Edit `terraform/terraform.tfvars`:

```hcl
# Basic Configuration
environment         = "dev"              # dev, staging, prod
location            = "East US"          # Azure region
resource_group_name = "rg-aks-novartis-dev"
cluster_name        = "aks-novartis-dev"

# Node Pool Configuration
default_node_pool_vm_size   = "Standard_D4s_v3"  # VM size
default_node_pool_min_count = 2                   # Min nodes
default_node_pool_max_count = 5                   # Max nodes

# Kubernetes Version
kubernetes_version = "1.28.3"  # Update as needed

# Features
enable_auto_scaling  = true   # Enable autoscaling
enable_azure_policy  = true   # Enable Azure Policy
enable_oms_agent     = true   # Enable monitoring
```

### Available VM Sizes

| VM Size | vCPUs | RAM | Use Case |
|---------|-------|-----|----------|
| Standard_D2s_v3 | 2 | 8 GB | Dev/Test |
| Standard_D4s_v3 | 4 | 16 GB | Small workloads |
| Standard_D8s_v3 | 8 | 32 GB | Medium workloads |
| Standard_D16s_v3 | 16 | 64 GB | Large workloads |

---

## 🔒 Security Features

This deployment includes:

### Authentication & Authorization
- ✅ **Certificate-based authentication** (secure, no secrets)
- ✅ **Azure AD integration** for RBAC
- ✅ **Managed identities** for AKS components

### Network Security
- ✅ **Azure CNI** for advanced networking
- ✅ **Network policies** (Azure Network Policy)
- ✅ **Private API server** (optional)

### Monitoring & Compliance
- ✅ **Azure Monitor** integration
- ✅ **Log Analytics** workspace
- ✅ **Azure Policy** add-on

---

## 📊 What Gets Deployed

### Resource Group
- **Name:** `rg-aks-novartis-dev`
- **Location:** East US
- **Purpose:** Contains all AKS resources

### AKS Cluster
- **Name:** `aks-novartis-dev`
- **Kubernetes Version:** 1.28.3
- **Identity:** System-assigned managed identity
- **Availability:** 3 Availability Zones

### Node Pools

#### System Node Pool (Required)
- **Name:** `systempool`
- **Purpose:** System components (CoreDNS, metrics-server, etc.)
- **Size:** Standard_D4s_v3 (4 vCPUs, 16 GB RAM)
- **Count:** 2-5 nodes (autoscaling)
- **OS Disk:** 100 GB Managed

#### User Node Pool (Optional)
- **Name:** `userpool`
- **Purpose:** Application workloads
- **Size:** Standard_D8s_v3 (8 vCPUs, 32 GB RAM)
- **Count:** 2-10 nodes (autoscaling)
- **Enable:** Set `enable_user_node_pool = true`

### Log Analytics Workspace
- **Name:** `log-aks-novartis-dev`
- **Retention:** 30 days
- **Purpose:** Cluster monitoring and diagnostics

---

## 🎯 Pipeline Stages

### Stage 1: Validate & Plan
1. Install Terraform
2. Initialize Terraform
3. Validate configuration
4. Check format
5. Create execution plan
6. Publish plan artifact

### Stage 2: Deploy AKS
1. Download plan
2. Apply Terraform
3. Get AKS credentials
4. Verify deployment
5. Show cluster info

### Stage 3: Post-Deployment
1. Generate documentation
2. Publish artifacts
3. Send notifications (optional)

---

## 📈 Cost Estimation

### Estimated Monthly Cost (Development)

| Resource | Configuration | Est. Cost/Month |
|----------|--------------|-----------------|
| AKS Management | Free | $0 |
| System Nodes (2x D4s_v3) | 4 vCPUs, 16 GB | ~$280 |
| Log Analytics | 5 GB/day | ~$15 |
| **Total** | | **~$295/month** |

**Note:** Costs vary based on:
- Number of nodes
- VM sizes
- Data ingestion
- Egress traffic
- Load balancer usage

**Cost Optimization:**
- Use autoscaling (scale to 0 when not needed)
- Stop cluster during non-business hours
- Use spot instances for non-critical workloads
- Monitor with Azure Cost Management

---

## 🔧 Common Operations

### Scale Node Pool
```bash
az aks nodepool scale \
  --resource-group rg-aks-novartis-dev \
  --cluster-name aks-novartis-dev \
  --name systempool \
  --node-count 3
```

### Upgrade Kubernetes Version
```bash
# Check available versions
az aks get-upgrades \
  --resource-group rg-aks-novartis-dev \
  --name aks-novartis-dev \
  --output table

# Upgrade cluster
az aks upgrade \
  --resource-group rg-aks-novartis-dev \
  --name aks-novartis-dev \
  --kubernetes-version 1.28.5
```

### View Logs
```bash
# Get cluster diagnostics
az aks get-credentials \
  --resource-group rg-aks-novartis-dev \
  --name aks-novartis-dev

kubectl get pods --all-namespaces
kubectl logs -n kube-system <pod-name>
```

### Delete Cluster
```bash
# Via Terraform (recommended)
cd terraform
terraform destroy

# Or via Azure CLI
az aks delete \
  --resource-group rg-aks-novartis-dev \
  --name aks-novartis-dev \
  --yes --no-wait
```

---

## 🧪 Testing the Cluster

### Deploy Sample Application
```bash
# Deploy nginx
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Check status
kubectl get service nginx

# Get external IP
kubectl get service nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Run Diagnostics
```bash
# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check cluster info
kubectl cluster-info

# View events
kubectl get events --all-namespaces
```

---

## 📚 Documentation

- **Deployment Guide:** `docs/DEPLOYMENT-GUIDE.md`
- **Troubleshooting:** `docs/TROUBLESHOOTING.md`
- **Certificate Auth Setup:** `../README.md`
- **Azure AKS Docs:** https://docs.microsoft.com/en-us/azure/aks/

---

## 🔄 CI/CD Integration

### Deploying Applications to AKS

After AKS is deployed, you can create additional pipelines to deploy applications:

```yaml
# Example: Deploy application to AKS
steps:
- task: AzureCLI@2
  inputs:
    azureSubscription: 'azure-cert-sp-connection'
    scriptType: 'bash'
    inlineScript: |
      # Get AKS credentials
      az aks get-credentials \
        --resource-group rg-aks-novartis-dev \
        --name aks-novartis-dev
      
      # Deploy application
      kubectl apply -f k8s/deployment.yaml
      
      # Wait for rollout
      kubectl rollout status deployment/myapp
```

---

## ⚠️ Important Notes

### Certificate Expiry
- **Expires:** December 11, 2026
- **Reminder:** Set calendar alert for November 11, 2026
- **Renewal:** See `../README.md` for renewal process

### Best Practices
- ✅ Use separate clusters for dev/staging/prod
- ✅ Enable autoscaling for cost optimization
- ✅ Monitor resource usage regularly
- ✅ Keep Kubernetes version up to date
- ✅ Use namespaces for workload isolation
- ✅ Implement resource quotas and limits
- ✅ Regular backups of cluster state

### Security Considerations
- 🔒 Limit access to AKS API server
- 🔒 Use Azure Policy for compliance
- 🔒 Enable pod security policies
- 🔒 Scan container images for vulnerabilities
- 🔒 Rotate service principal credentials regularly

---

## 🆘 Support & Troubleshooting

### Common Issues

**Issue:** Terraform plan fails with authentication error
```bash
# Solution: Verify service connection
az account show  # Should show your subscription
```

**Issue:** AKS nodes not ready
```bash
# Solution: Check node pool status
az aks nodepool show \
  --resource-group rg-aks-novartis-dev \
  --cluster-name aks-novartis-dev \
  --name systempool
```

**Issue:** Cannot connect to cluster
```bash
# Solution: Get credentials again
az aks get-credentials \
  --resource-group rg-aks-novartis-dev \
  --name aks-novartis-dev \
  --overwrite-existing
```

For more issues, see `docs/TROUBLESHOOTING.md`

---

## ✅ Next Steps

After deployment:

1. **Configure kubectl access** for your team
2. **Set up Ingress controller** (nginx-ingress or Azure App Gateway)
3. **Deploy cert-manager** for TLS certificates
4. **Configure monitoring** dashboards in Azure Monitor
5. **Set up GitOps** with Flux or ArgoCD
6. **Implement backup** strategy with Velero
7. **Deploy sample applications**

---

## 📞 Contact & Support

- **Azure DevOps:** https://dev.azure.com/nirmata/anudeep
- **Service Connection:** azure-cert-sp-connection
- **Documentation:** See docs/ folder

---

**Status:** ✅ Ready for deployment  
**Last Updated:** December 11, 2025  
**Maintained By:** DevOps Team

