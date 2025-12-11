# 🚀 Quick Start - Windows AKS Cluster

Deploy a private AKS cluster with Windows node pools in 5 commands!

---

## ⚡ Super Quick Deployment

```bash
# 1. Navigate
cd /Users/anudeepnalla/Downloads/novartis/azure-cert/novartis-azure-devops/terraform-aks-windows/terraform

# 2. Authenticate
az login --service-principal \
  --username 042aea62-c886-46a1-b2f8-25c9af22a2db \
  --tenant 3d95acd6-b6ee-428e-a7a0-196120fc3c65 \
  --certificate ../../certs/service-principal-combined.pem

# 3. Initialize
terraform init

# 4. Plan
terraform plan

# 5. Deploy
terraform apply
```

**Time:** 20-25 minutes ⏱️

---

## 🪟 What You Get

```
Private AKS Cluster: aks-windows-cluster
├── Linux Pool (linuxpool)
│   ├── 1 node × Standard_B2s
│   └── Purpose: Kubernetes system
│
└── Windows Pool (winpool)
    ├── 1 node × Standard_B2s
    ├── OS: Windows Server 2022
    └── Purpose: Your Windows apps
```

---

## 🔑 Get Windows Admin Password

```bash
cd terraform

# After deployment
terraform output windows_admin_password
```

---

## 🧪 Deploy Test Windows App

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
    value: "windows"
    effect: "NoSchedule"
  containers:
  - name: iis
    image: mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022
EOF

# Check status
kubectl get pod iis-test
```

---

## 📊 Key Differences from Linux Cluster

| Feature | Linux Cluster | Windows Cluster |
|---------|---------------|-----------------|
| **Node Pools** | All Linux | Linux (system) + Windows (user) |
| **Min Nodes** | 1 | 2 (1 Linux + 1 Windows) |
| **Admin Access** | SSH keys | Username + Password |
| **Container Images** | Linux only | Windows only (on Windows nodes) |
| **Boot Time** | ~2 minutes | ~5-8 minutes (Windows) |

---

## ⚠️ Important Notes

### **Windows Requirements**
- ✅ **Must have Linux system pool** (Kubernetes requirement)
- ✅ **Windows Server 2022** (default OS)
- ✅ **Larger VMs** recommended (min D2s_v3 for production)
- ✅ **128 GB OS disk** (Windows needs more space)

### **Container Compatibility**
- ✅ Use Windows container images
- ✅ Match Windows Server version (2022)
- ❌ Linux containers won't run on Windows nodes

### **Node Selectors**
Always add to Windows pods:
```yaml
nodeSelector:
  kubernetes.io/os: windows
tolerations:
- key: "os"
  value: "windows"
  effect: "NoSchedule"
```

---

## 💡 Pro Tips

1. **Start Small** - Use B2s for testing, upgrade to Ds_v3 for production
2. **Linux Pool** - Keep it minimal (1-2 nodes), it's just for system components
3. **Windows Pool** - Scale this based on your app needs
4. **Image Versions** - Match Windows Server version in container images
5. **Private Cluster** - Remember to use Jump Box or command invoke

---

## 📚 Documentation

- **README.md** - Complete overview
- **DEPLOYMENT-GUIDE.md** - Detailed deployment guide
- **../HOW-CERTIFICATE-AUTH-WORKS.md** - Authentication explanation

---

**Ready to deploy your Windows AKS cluster?** Run the commands above! 🪟🚀

