#############################################
# Nirmata Provider Configuration
#############################################
provider "nirmata" {
  token = var.nirmata_token
  url   = var.nirmata_url
}

#############################################
# Local Variables
#############################################
locals {
  cluster_name                = module.eks.cluster_name
  cluster_endpoint            = module.eks.cluster_endpoint
  cluster_ca_certificate_data = module.eks.cluster_certificate_authority_data
}

#############################################
# Register EKS Cluster with Nirmata
#############################################
resource "nirmata_cluster_registered" "eks-registered" {
  name         = var.nirmata_cluster_name
  cluster_type = var.nirmata_cluster_type
  endpoint     = local.cluster_endpoint

  depends_on = [module.eks]
}

#############################################
# Apply Nirmata Controllers
#############################################
resource "null_resource" "apply_controllers" {
  depends_on = [nirmata_cluster_registered.eks-registered]

  triggers = {
    always_run = timestamp()
  }

  # 1) Configure kubectl with explicit environment variables
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${local.cluster_name} --profile ${var.aws_profile}"

    environment = {
      AWS_PROFILE        = var.aws_profile
      AWS_DEFAULT_REGION = var.aws_region
      HOME               = pathexpand("~")
    }
  }

  # 2) Verify kubectl connectivity
  provisioner "local-exec" {
    command = "kubectl cluster-info"

    environment = {
      AWS_PROFILE        = var.aws_profile
      AWS_DEFAULT_REGION = var.aws_region
      KUBECONFIG         = "${pathexpand("~")}/.kube/config"
    }
  }

  # 3) List controller files for debugging
  provisioner "local-exec" {
    command = "ls -la ${nirmata_cluster_registered.eks-registered.controller_yamls_folder} > controller_files.txt"
  }

  # 4) Apply namespace manifests (temp-01-*)
  provisioner "local-exec" {
    command = "for f in ${nirmata_cluster_registered.eks-registered.controller_yamls_folder}/temp-01-*; do kubectl apply -f \"$f\"; done"

    environment = {
      AWS_PROFILE        = var.aws_profile
      AWS_DEFAULT_REGION = var.aws_region
      KUBECONFIG         = "${pathexpand("~")}/.kube/config"
    }
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

  # 5) Apply service account manifests (temp-02-*)
  provisioner "local-exec" {
    command = "for f in ${nirmata_cluster_registered.eks-registered.controller_yamls_folder}/temp-02-*; do kubectl apply -f \"$f\"; done"

    environment = {
      AWS_PROFILE        = var.aws_profile
      AWS_DEFAULT_REGION = var.aws_region
      KUBECONFIG         = "${pathexpand("~")}/.kube/config"
    }
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

  # 6) Apply CRD/RBAC/Config manifests (temp-03-*)
  provisioner "local-exec" {
    command = "for f in ${nirmata_cluster_registered.eks-registered.controller_yamls_folder}/temp-03-*; do kubectl apply -f \"$f\"; done"

    environment = {
      AWS_PROFILE        = var.aws_profile
      AWS_DEFAULT_REGION = var.aws_region
      KUBECONFIG         = "${pathexpand("~")}/.kube/config"
    }
  }

  provisioner "local-exec" {
    command = "sleep 20"
  }

  # 7) Modify nirmata-kube-controller deployment to add -insecure flag
  provisioner "local-exec" {
    command = <<-EOT
      set -e

      for f in ${nirmata_cluster_registered.eks-registered.controller_yamls_folder}/temp-04-*; do
        # Skip backup files created by sed (-i.bak)
        case "$f" in
          *.bak) continue ;;
        esac

        # Only care about files defining the nirmata-kube-controller deployment
        if grep -q "nirmata-kube-controller" "$f"; then

          echo "Processing file for nirmata-kube-controller: $f"

          # Skip if -insecure is already in the file
          if grep -q '"-insecure"' "$f"; then
            echo "-insecure flag already present in $f, skipping patch"
            continue
          fi

          # Insert - "-insecure" after the - "10m" line, preserving indentation
          sed -i.bak -E 's/^([[:space:]]*)- "10m"/\1- "10m"\
\1- "-insecure"/' "$f"

          echo "Added -insecure flag in $f. Args context:"
          awk 'NR>=l-5 && NR<=l+5 {print NR ":" $0} /10m/ {l=NR}' "$f" || true

        fi
      done
    EOT
  }

  # 8) Apply deployment manifests (temp-04-*) but SKIP kyverno-operator manifests
  provisioner "local-exec" {
    command = <<-EOT
      set -e

      for f in ${nirmata_cluster_registered.eks-registered.controller_yamls_folder}/temp-04-*; do
        # Skip backup files
        case "$f" in
          *.bak) continue ;;
        esac

        # If the file contains kyverno-operator, skip applying it
        if grep -q "kyverno-operator" "$f"; then
          echo "Skipping kyverno-operator manifest: $f"
          continue
        fi

        echo "Applying deployment manifest: $f"
        kubectl apply -f "$f"
      done
    EOT

    environment = {
      AWS_PROFILE        = var.aws_profile
      AWS_DEFAULT_REGION = var.aws_region
      KUBECONFIG         = "${pathexpand("~")}/.kube/config"
    }
  }

  # 9) Wait for kyverno-operator (if any) to be created by controllers
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting 120 seconds to allow any kyverno-operator deployment to appear..."
      sleep 120
    EOT

    environment = {
      AWS_PROFILE        = var.aws_profile
      AWS_DEFAULT_REGION = var.aws_region
      KUBECONFIG         = "${pathexpand("~")}/.kube/config"
    }
  }

  # 10) Explicitly delete kyverno-operator deployment if it exists (cluster-wide)
  provisioner "local-exec" {
    command = <<-EOT
      set -e

      echo "Looking for kyverno-operator deployments in all namespaces..."

      deployments=$(kubectl get deployments --all-namespaces -o jsonpath='{range .items[?(@.metadata.name=="kyverno-operator")]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}')

      if [ -z "$deployments" ]; then
        echo "No kyverno-operator deployments found. Nothing to delete."
        exit 0
      fi

      echo "Found kyverno-operator deployments:"
      echo "$deployments"

      echo "$deployments" | while read ns name; do
        if [ -n "$ns" ] && [ -n "$name" ]; then
          echo "Deleting deployment $name in namespace $ns"
          kubectl delete deployment "$name" -n "$ns" --ignore-not-found=true
        fi
      done

      echo "kyverno-operator cleanup complete."
    EOT

    environment = {
      AWS_PROFILE        = var.aws_profile
      AWS_DEFAULT_REGION = var.aws_region
      KUBECONFIG         = "${pathexpand("~")}/.kube/config"
    }
  }
}

