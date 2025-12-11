# Sample Applications for AKS Clusters

Sample applications for testing your Linux and Windows AKS clusters.

---

## 📁 What's Included

### **Windows Applications** (windows/)
1. **iis-app.yaml** - IIS Web Server on Windows Server 2022
2. **dotnet-app.yaml** - .NET sample application

### **Linux Applications** (linux/)
1. **nginx-app.yaml** - NGINX web server with custom page

---

## 🚀 Quick Deploy

### **Automated Deployment (Easiest)**
```bash
cd sample-apps
./deploy-samples.sh
```

The script will:
- Ask which cluster (Linux/Windows/Both)
- Get credentials automatically
- Deploy applications
- Show verification commands

---

## 🪟 Deploy to Windows Cluster

### **Method 1: Deploy IIS**

```bash
# Get Windows cluster credentials
az aks get-credentials \
  --resource-group rg-anudeep \
  --name aks-win-cluster \
  --overwrite-existing

# Deploy IIS
kubectl apply -f windows/iis-app.yaml

# Check status
kubectl get pods -l app=iis-app --watch

# Get service IP (for internal access)
kubectl get service iis-service
```

### **Method 2: Deploy .NET App**

```bash
# Get Windows cluster credentials
az aks get-credentials \
  --resource-group rg-anudeep \
  --name aks-win-cluster

# Deploy .NET app
kubectl apply -f windows/dotnet-app.yaml

# Check status
kubectl get pods -l app=dotnet-app

# Get service
kubectl get service dotnet-service
```

---

## 🐧 Deploy to Linux Cluster

### **Deploy NGINX**

```bash
# Get Linux cluster credentials
az aks get-credentials \
  --resource-group rg-anudeep \
  --name aks-novartis-dev \
  --overwrite-existing

# Deploy NGINX
kubectl apply -f linux/nginx-app.yaml

# Check status
kubectl get pods -l app=nginx

# Get service
kubectl get service nginx-service
```

---

## 🔍 Verify Deployments

### **Check Pods**
```bash
# All pods
kubectl get pods --all-namespaces -o wide

# Windows pods (should be on win01 nodes)
kubectl get pods -l kubernetes.io/os=windows -o wide

# Linux pods
kubectl get pods -l kubernetes.io/os=linux -o wide
```

### **Check Services**
```bash
# All services
kubectl get services --all-namespaces

# Get external/internal IPs
kubectl get svc
```

### **Check Node Placement**
```bash
# Verify pods are on correct node types
kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,OS:.spec.nodeSelector
```

---

## 🌐 Accessing Applications

### **⚠️ Private Clusters Cannot Access Load Balancer IPs Directly!**

Your clusters are **PRIVATE**, so you have several access options:

### **Option 1: Port Forward (Recommended for Testing)**

```bash
# Forward NGINX (Linux)
kubectl config use-context aks-novartis-dev
kubectl port-forward service/nginx-service 8080:80

# In another terminal, forward IIS (Windows)
kubectl config use-context aks-win-cluster
kubectl port-forward service/iis-service 8081:80

# Then open in browser:
open http://localhost:8080  # NGINX
open http://localhost:8081  # IIS
```

### **Option 2: Use Internal Load Balancer**

Edit the service files and uncomment the annotation:

```yaml
annotations:
  service.beta.kubernetes.io/azure-load-balancer-internal: "true"
```

Then access from a VM in the same VNet.

### **Option 3: Azure CLI Command Invoke**

```bash
# Run commands on the cluster without direct access
az aks command invoke \
  --resource-group rg-anudeep \
  --name aks-win-cluster \
  --command "kubectl get pods"

# Get service details
az aks command invoke \
  --resource-group rg-anudeep \
  --name aks-win-cluster \
  --command "kubectl get svc"
```

### **Option 4: Jump Box (Best for Regular Use)**

Create a VM in the same VNet:

```bash
az vm create \
  --resource-group rg-anudeep \
  --name vm-jumpbox \
  --image Ubuntu2204 \
  --vnet-name vnet-aks-novartis-dev \
  --subnet snet-aks-nodes \
  --admin-username azureuser \
  --generate-ssh-keys \
  --size Standard_B2s

# SSH to it
ssh azureuser@<VM_PUBLIC_IP>

# Install kubectl, get credentials, access services
```

---

## 🧪 Testing Windows Applications

### **Test IIS is Working**

```bash
# Get pod name
kubectl get pods -l app=iis-app

# Exec into pod
kubectl exec -it <iis-pod-name> -- powershell

# Inside the pod:
PS> Get-Service W3SVC
PS> Test-NetConnection localhost -Port 80
PS> curl http://localhost

# Exit
PS> exit
```

### **Test .NET App**

```bash
# Port forward
kubectl port-forward service/dotnet-service 8082:80

# In browser or curl
curl http://localhost:8082
```

### **View Windows Logs**

```bash
# Get logs from Windows pod
kubectl logs -l app=iis-app

# Follow logs
kubectl logs -f <windows-pod-name>
```

---

## 📊 Application Details

### **IIS Application**
```yaml
Image:       mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022
Replicas:    2
Resources:   512Mi RAM, 250m CPU (request)
Port:        80
Service:     LoadBalancer
```

### **.NET Application**
```yaml
Image:       mcr.microsoft.com/dotnet/samples:aspnetapp
Replicas:    3
Resources:   256Mi RAM, 200m CPU (request)
Port:        8080
Service:     LoadBalancer
```

### **NGINX Application**
```yaml
Image:       nginx:latest
Replicas:    3
Resources:   128Mi RAM, 100m CPU (request)
Port:        80
Service:     LoadBalancer
```

---

## 🔧 Common Operations

### **Scale Applications**

```bash
# Scale NGINX
kubectl scale deployment nginx-app --replicas=5

# Scale IIS
kubectl scale deployment iis-app --replicas=4

# Check scaling
kubectl get deployment
```

### **Update Applications**

```bash
# Update image
kubectl set image deployment/nginx-app nginx=nginx:1.25

# Rollout status
kubectl rollout status deployment/nginx-app

# Rollback if needed
kubectl rollout undo deployment/nginx-app
```

### **Delete Applications**

```bash
# Delete NGINX
kubectl delete -f linux/nginx-app.yaml

# Delete IIS
kubectl delete -f windows/iis-app.yaml

# Delete .NET app
kubectl delete -f windows/dotnet-app.yaml
```

---

## 💡 Pro Tips

### **Windows Application Tips**

1. **Always include node selector and tolerations** for Windows pods
2. **Use Windows Server 2022 base images** (ltsc2022)
3. **Allow more boot time** (initialDelaySeconds: 60)
4. **Larger resource requests** (Windows needs more RAM)
5. **Check Windows node is Ready** before deploying

### **Debugging Windows Pods**

```bash
# Describe pod
kubectl describe pod <windows-pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp' | grep <pod-name>

# Exec into Windows pod
kubectl exec -it <windows-pod-name> -- powershell

# View Windows logs
kubectl logs <windows-pod-name> --tail=50
```

---

## 📚 Additional Sample Apps

### **Windows SQL Server**
```yaml
# Example: SQL Server on Windows
image: mcr.microsoft.com/mssql/server:2022-latest
# Requires: nodeSelector and tolerations for Windows
```

### **.NET Core API**
```yaml
# Example: .NET 8 API
image: mcr.microsoft.com/dotnet/aspnet:8.0
# Can run on either Linux or Windows!
```

---

## ✅ Deployment Checklist

- [ ] AKS cluster credentials obtained
- [ ] Cluster is healthy (`kubectl get nodes`)
- [ ] Windows nodes are Ready (if deploying Windows apps)
- [ ] Application YAML reviewed
- [ ] NodeSelector and tolerations configured (for Windows)
- [ ] Resources deployed
- [ ] Pods are Running
- [ ] Services created
- [ ] Applications tested

---

## 🆘 Troubleshooting

### **Windows Pod Pending**
```bash
# Check events
kubectl describe pod <pod-name>

# Common issues:
# - Windows node not ready yet (wait 5-10 min)
# - Missing toleration for Windows taint
# - Image pull issues (check image name)
```

### **Pod CrashLoopBackOff**
```bash
# Check logs
kubectl logs <pod-name>

# Check resource limits
kubectl describe pod <pod-name> | grep -A 5 Limits
```

### **Service No External IP**
```bash
# For private clusters, use internal LB or port-forward
# Or access from Jump Box in same VNet
```

---

**Status:** ✅ Ready to deploy  
**Applications:** 3 (2 Windows + 1 Linux)  
**Deployment:** Automated script available

---

**Deploy with:** `./deploy-samples.sh`

