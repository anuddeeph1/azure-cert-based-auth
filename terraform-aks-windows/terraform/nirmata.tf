#############################################
# Nirmata Provider Configuration for Windows AKS
# (Provider requirements are in providers.tf)
#############################################

provider "nirmata" {
  token = var.nirmata_token
  url   = var.nirmata_url
}

#############################################
# Local Variables for Windows AKS
#############################################
locals {
  aks_cluster_name                = azurerm_kubernetes_cluster.aks.name
  aks_cluster_endpoint            = azurerm_kubernetes_cluster.aks.kube_config[0].host
  aks_cluster_ca_certificate_data = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  aks_resource_group              = var.resource_group_name
}

#############################################
# Register Windows AKS Cluster with Nirmata
#############################################
resource "nirmata_cluster_registered" "aks_windows_registered" {
  count        = var.enable_nirmata ? 1 : 0
  name         = var.nirmata_cluster_name
  cluster_type = var.nirmata_cluster_type
  endpoint     = local.aks_cluster_endpoint

  depends_on = [azurerm_kubernetes_cluster.aks]
}

#############################################
# Apply Nirmata Controllers to Windows AKS
#############################################
resource "null_resource" "apply_nirmata_controllers_windows" {
  count = var.enable_nirmata ? 1 : 0
  
  depends_on = [
    nirmata_cluster_registered.aks_windows_registered[0],
    azurerm_kubernetes_cluster.aks,
    azurerm_kubernetes_cluster_node_pool.windows[0]
  ]

  triggers = {
    always_run = timestamp()
  }

  # 1) Configure kubectl for Windows AKS using Azure CLI
  provisioner "local-exec" {
    command = <<-EOT
      az aks get-credentials \
        --resource-group ${local.aks_resource_group} \
        --name ${local.aks_cluster_name} \
        --overwrite-existing \
        --admin
    EOT

    environment = {
      KUBECONFIG = "${pathexpand("~")}/.kube/config"
    }
  }

  # 2) Verify kubectl connectivity
  provisioner "local-exec" {
    command = "kubectl cluster-info"

    environment = {
      KUBECONFIG = "${pathexpand("~")}/.kube/config"
    }
  }

  # 3) List controller files
  provisioner "local-exec" {
    command = "ls -la ${nirmata_cluster_registered.aks_windows_registered[0].controller_yamls_folder} > nirmata_controller_files.txt || echo 'Controller files not yet available'"
  }

  # 4) Apply namespace manifests (temp-01-*)
  provisioner "local-exec" {
    command = <<-EOT
      echo "Applying Nirmata namespace manifests..."
      for f in ${nirmata_cluster_registered.aks_windows_registered[0].controller_yamls_folder}/temp-01-*; do
        if [ -f "$f" ]; then
          echo "Applying: $f"
          kubectl apply -f "$f"
        fi
      done
    EOT

    environment = {
      KUBECONFIG = "${pathexpand("~")}/.kube/config"
    }
  }

  # 5) Wait for namespaces
  provisioner "local-exec" {
    command = "sleep 10"
  }

  # 6) Apply service account manifests (temp-02-*)
  provisioner "local-exec" {
    command = <<-EOT
      echo "Applying Nirmata service account manifests..."
      for f in ${nirmata_cluster_registered.aks_windows_registered[0].controller_yamls_folder}/temp-02-*; do
        if [ -f "$f" ]; then
          echo "Applying: $f"
          kubectl apply -f "$f"
        fi
      done
    EOT

    environment = {
      KUBECONFIG = "${pathexpand("~")}/.kube/config"
    }
  }

  # 7) Wait for service accounts
  provisioner "local-exec" {
    command = "sleep 10"
  }

  # 8) Apply CRD/RBAC/Config manifests (temp-03-*)
  provisioner "local-exec" {
    command = <<-EOT
      echo "Applying Nirmata CRD/RBAC/Config manifests..."
      for f in ${nirmata_cluster_registered.aks_windows_registered[0].controller_yamls_folder}/temp-03-*; do
        if [ -f "$f" ]; then
          echo "Applying: $f"
          kubectl apply -f "$f"
        fi
      done
    EOT

    environment = {
      KUBECONFIG = "${pathexpand("~")}/.kube/config"
    }
  }

  # 9) Wait for CRDs
  provisioner "local-exec" {
    command = "sleep 20"
  }

  # 10) Modify nirmata-kube-controller to add -insecure flag
  provisioner "local-exec" {
    command = <<-EOT
      set -e

      echo "Modifying nirmata-kube-controller deployment..."

      for f in ${nirmata_cluster_registered.aks_windows_registered[0].controller_yamls_folder}/temp-04-*; do
        case "$f" in
          *.bak) continue ;;
        esac

        if [ -f "$f" ] && grep -q "nirmata-kube-controller" "$f"; then
          echo "Processing: $f"

          if grep -q '"-insecure"' "$f"; then
            echo "-insecure flag already present, skipping"
            continue
          fi

          sed -i.bak -E 's/^([[:space:]]*)- "10m"/\1- "10m"\
\1- "-insecure"/' "$f"

          echo "Added -insecure flag to $f"
        fi
      done
    EOT
  }

  # 11) Apply deployment manifests (temp-04-*) but SKIP kyverno-operator
  provisioner "local-exec" {
    command = <<-EOT
      set -e

      echo "Applying Nirmata deployment manifests..."

      for f in ${nirmata_cluster_registered.aks_windows_registered[0].controller_yamls_folder}/temp-04-*; do
        case "$f" in
          *.bak) continue ;;
        esac

        if [ -f "$f" ]; then
          if grep -q "kyverno-operator" "$f"; then
            echo "Skipping kyverno-operator: $f"
            continue
          fi

          echo "Applying: $f"
          kubectl apply -f "$f"
        fi
      done
    EOT

    environment = {
      KUBECONFIG = "${pathexpand("~")}/.kube/config"
    }
  }

  # 12) Wait for kyverno-operator
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting 120 seconds for kyverno-operator..."
      sleep 120
    EOT
  }

  # 13) Delete kyverno-operator if it exists
  provisioner "local-exec" {
    command = <<-EOT
      set -e

      echo "Checking for kyverno-operator deployments..."

      deployments=$(kubectl get deployments --all-namespaces -o jsonpath='{range .items[?(@.metadata.name=="kyverno-operator")]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}')

      if [ -z "$deployments" ]; then
        echo "No kyverno-operator found."
        exit 0
      fi

      echo "Found kyverno-operator:"
      echo "$deployments"

      echo "$deployments" | while read ns name; do
        if [ -n "$ns" ] && [ -n "$name" ]; then
          echo "Deleting: $name in $ns"
          kubectl delete deployment "$name" -n "$ns" --ignore-not-found=true
        fi
      done

      echo "✓ kyverno-operator cleanup complete"
    EOT

    environment = {
      KUBECONFIG = "${pathexpand("~")}/.kube/config"
    }
  }

  # 14) Verify Nirmata controller
  provisioner "local-exec" {
    command = <<-EOT
      echo "Verifying Nirmata controller..."
      sleep 30
      kubectl get pods -n nirmata --selector=app=nirmata-kube-controller || echo "Nirmata pods not yet ready"
      kubectl get deployments -n nirmata || echo "Nirmata namespace not yet created"
    EOT

    environment = {
      KUBECONFIG = "${pathexpand("~")}/.kube/config"
    }
  }
}

#############################################
# Outputs for Nirmata Integration
#############################################
output "nirmata_cluster_id" {
  description = "Nirmata cluster ID"
  value       = var.enable_nirmata ? nirmata_cluster_registered.aks_windows_registered[0].id : null
}

output "nirmata_cluster_name" {
  description = "Nirmata registered cluster name"
  value       = var.enable_nirmata ? nirmata_cluster_registered.aks_windows_registered[0].name : null
}

output "nirmata_controller_yamls_folder" {
  description = "Path to Nirmata controller YAML files"
  value       = var.enable_nirmata ? nirmata_cluster_registered.aks_windows_registered[0].controller_yamls_folder : null
}

