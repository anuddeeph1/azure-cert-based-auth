#!/bin/bash

# Deploy Sample Applications to AKS Clusters
# Supports both Windows and Linux clusters

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Sample Application Deployment"
echo "=========================================="
echo ""
echo "You have TWO AKS clusters:"
echo "  1. Linux cluster (aks-novartis-dev)"
echo "  2. Windows cluster (aks-win-cluster)"
echo ""
echo "Which cluster do you want to deploy to?"
echo "  1) Linux cluster"
echo "  2) Windows cluster"
echo "  3) Both clusters"
echo ""
read -p "Enter choice (1-3): " CHOICE

case $CHOICE in
  1)
    DEPLOY_LINUX=true
    DEPLOY_WINDOWS=false
    ;;
  2)
    DEPLOY_LINUX=false
    DEPLOY_WINDOWS=true
    ;;
  3)
    DEPLOY_LINUX=true
    DEPLOY_WINDOWS=true
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

# Deploy to Linux Cluster
if [ "$DEPLOY_LINUX" = true ]; then
  echo ""
  echo "=========================================="
  echo "Deploying to Linux Cluster"
  echo "=========================================="
  
  # Get credentials for Linux cluster
  echo "Getting credentials for aks-novartis-dev..."
  az aks get-credentials \
    --resource-group rg-anudeep \
    --name aks-novartis-dev \
    --overwrite-existing
  
  echo ""
  echo "Deploying NGINX application..."
  kubectl apply -f "$SCRIPT_DIR/linux/nginx-app.yaml"
  
  echo ""
  echo "✓ NGINX app deployed to Linux cluster"
  echo ""
  echo "Check status:"
  echo "  kubectl get pods -l app=nginx"
  echo "  kubectl get service nginx-service"
  echo ""
fi

# Deploy to Windows Cluster
if [ "$DEPLOY_WINDOWS" = true ]; then
  echo ""
  echo "=========================================="
  echo "Deploying to Windows Cluster"
  echo "=========================================="
  
  # Get credentials for Windows cluster
  echo "Getting credentials for aks-win-cluster..."
  az aks get-credentials \
    --resource-group rg-anudeep \
    --name aks-win-cluster \
    --overwrite-existing
  
  echo ""
  echo "Which Windows app do you want to deploy?"
  echo "  1) IIS Web Server"
  echo "  2) .NET Sample App"
  echo "  3) Both"
  echo ""
  read -p "Enter choice (1-3): " WIN_CHOICE
  
  case $WIN_CHOICE in
    1|3)
      echo ""
      echo "Deploying IIS application..."
      kubectl apply -f "$SCRIPT_DIR/windows/iis-app.yaml"
      echo "✓ IIS app deployed"
      ;;
  esac
  
  case $WIN_CHOICE in
    2|3)
      echo ""
      echo "Deploying .NET application..."
      kubectl apply -f "$SCRIPT_DIR/windows/dotnet-app.yaml"
      echo "✓ .NET app deployed"
      ;;
  esac
  
  echo ""
  echo "✓ Apps deployed to Windows cluster"
  echo ""
  echo "Check status:"
  echo "  kubectl get pods --all-namespaces"
  echo "  kubectl get services"
  echo ""
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "⚠️  PRIVATE CLUSTERS - Cannot access Load Balancer IPs directly"
echo ""
echo "To access services in private clusters:"
echo ""
echo "Option 1: Use kubectl port-forward"
echo "  kubectl port-forward service/nginx-service 8080:80"
echo "  kubectl port-forward service/iis-service 8081:80"
echo "  Then: open http://localhost:8080"
echo ""
echo "Option 2: Use az aks command invoke"
echo "  az aks command invoke --resource-group rg-anudeep --name aks-novartis-dev --command 'kubectl get svc'"
echo ""
echo "Option 3: Access from Jump Box VM (if created)"
echo ""
echo "View pods:"
echo "  kubectl get pods --all-namespaces -o wide"
echo ""
echo "View services:"
echo "  kubectl get services --all-namespaces"
echo ""

