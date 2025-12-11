# Use existing Resource Group
data "azurerm_resource_group" "aks" {
  name = var.resource_group_name
}

# Use existing Virtual Network
data "azurerm_virtual_network" "aks" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.aks.name
}

# Create new Subnet for Windows cluster in existing VNet
resource "azurerm_subnet" "aks_windows" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.aks.name
  virtual_network_name = data.azurerm_virtual_network.aks.name
  address_prefixes     = var.subnet_address_prefixes
}

# Use existing Log Analytics Workspace
data "azurerm_log_analytics_workspace" "aks" {
  name                = "log-aks-novartis-dev" # Existing Log Analytics
  resource_group_name = data.azurerm_resource_group.aks.name
}

# Random password for Windows admin
resource "random_password" "windows_admin" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# AKS Cluster with Windows Support
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = data.azurerm_resource_group.aks.location
  resource_group_name = data.azurerm_resource_group.aks.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Linux Node Pool (Required - System pool for Windows clusters)
  default_node_pool {
    name                = var.linux_node_pool_name
    vm_size             = var.linux_node_pool_vm_size
    enable_auto_scaling = var.enable_auto_scaling
    node_count          = var.enable_auto_scaling ? null : var.linux_node_pool_count
    min_count           = var.enable_auto_scaling ? var.linux_node_pool_min_count : null
    max_count           = var.enable_auto_scaling ? var.linux_node_pool_max_count : null
    max_pods            = 110
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"

    # Use the new Windows subnet in existing VNet
    vnet_subnet_id = azurerm_subnet.aks_windows.id

    # Availability Zones
    zones = ["1", "2", "3"]

    # Node labels
    node_labels = {
      "nodepool-type" = "linux-system"
      "environment"   = var.environment
      "os"            = "linux"
    }

    tags = merge(var.tags, {
      NodePool = "linux-system"
      OS       = "Linux"
    })
  }

  # Windows Profile (Required for Windows node pools)
  windows_profile {
    admin_username = var.windows_admin_username
    admin_password = random_password.windows_admin.result
  }

  # Network Profile
  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
  }

  # Private Cluster Configuration
  private_cluster_enabled             = var.enable_private_cluster
  private_cluster_public_fqdn_enabled = false

  # Azure AD Integration (RBAC)
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_rbac ? [1] : []
    content {
      managed                = true
      azure_rbac_enabled     = true
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  # Monitoring - use existing Log Analytics
  oms_agent {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.aks.id
  }

  # Azure Policy
  azure_policy_enabled = var.enable_azure_policy

  # Auto-upgrade
  automatic_channel_upgrade = "patch"

  # Maintenance Window
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4]
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version,
      windows_profile[0].admin_password # Don't update on password change
    ]
  }
}

# Windows Node Pool
resource "azurerm_kubernetes_cluster_node_pool" "windows" {
  count                 = var.enable_windows_node_pool ? 1 : 0
  name                  = var.windows_node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.windows_node_pool_vm_size
  os_type               = "Windows"
  os_sku                = "Windows2022" # Windows Server 2022

  enable_auto_scaling = var.enable_auto_scaling
  node_count          = var.enable_auto_scaling ? null : var.windows_node_pool_count
  min_count           = var.enable_auto_scaling ? var.windows_node_pool_min_count : null
  max_count           = var.enable_auto_scaling ? var.windows_node_pool_max_count : null

  max_pods        = 30
  os_disk_size_gb = 128
  os_disk_type    = "Managed"
  mode            = "User"

  zones = ["1", "2", "3"]

  node_labels = {
    "nodepool-type" = "windows"
    "environment"   = var.environment
    "os"            = "windows"
  }

  # Windows-specific node taints (forces Windows workloads to this pool)
  node_taints = [
    "os=windows:NoSchedule"
  ]

  tags = merge(var.tags, {
    NodePool = "windows"
    OS       = "Windows"
  })
}

