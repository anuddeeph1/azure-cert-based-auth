# Resource Group
resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network for Private AKS
resource "azurerm_virtual_network" "aks" {
  count               = var.create_vnet ? 1 : 0
  name                = var.vnet_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnet for AKS Nodes
resource "azurerm_subnet" "aks" {
  count                = var.create_vnet ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks[0].name
  address_prefixes     = var.subnet_address_prefixes
}

# Log Analytics Workspace for AKS Monitoring
resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.enable_oms_agent ? 1 : 0
  name                = "log-${var.cluster_name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  
  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Default Node Pool (System)
  default_node_pool {
    name                = var.default_node_pool_name
    vm_size             = var.default_node_pool_vm_size
    enable_auto_scaling = var.enable_auto_scaling
    node_count          = var.enable_auto_scaling ? null : var.default_node_pool_count
    min_count           = var.enable_auto_scaling ? var.default_node_pool_min_count : null
    max_count           = var.enable_auto_scaling ? var.default_node_pool_max_count : null
    max_pods            = var.default_node_pool_max_pods
    os_disk_size_gb     = 100
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"
    
    # Use VNet subnet if created
    vnet_subnet_id = var.create_vnet ? azurerm_subnet.aks[0].id : null
    
    # Availability Zones
    zones = ["1", "2", "3"]
    
    # Node labels
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
      "role"          = "system"
    }
    
    tags = merge(var.tags, {
      NodePool = "system"
    })
  }

  # Private Cluster Configuration
  private_cluster_enabled             = var.enable_private_cluster
  private_dns_zone_id                 = var.private_dns_zone_id
  private_cluster_public_fqdn_enabled = false

  # Network Profile
  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
    
    # For private cluster with custom VNet
    dynamic "load_balancer_profile" {
      for_each = var.enable_private_cluster ? [1] : []
      content {
        outbound_ip_address_ids = []
      }
    }
  }

  # Azure AD Integration (RBAC)
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_rbac ? [1] : []
    content {
      managed                = true
      azure_rbac_enabled     = true
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  # Monitoring
  dynamic "oms_agent" {
    for_each = var.enable_oms_agent ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id
    }
  }

  # Azure Policy Add-on
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
      kubernetes_version
    ]
  }
}

# Additional User Node Pool (Optional)
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count                 = var.enable_user_node_pool ? 1 : 0
  name                  = var.user_node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_pool_vm_size
  enable_auto_scaling   = true
  min_count             = 2
  max_count             = 10
  max_pods              = 30
  os_disk_size_gb       = 100
  os_disk_type          = "Managed"
  mode                  = "User"
  
  zones = ["1", "2", "3"]
  
  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
    "role"          = "application"
  }
  
  node_taints = []
  
  tags = merge(var.tags, {
    NodePool = "user"
  })
}

# Role Assignment for AKS to access ACR (if needed)
# Uncomment if you have Azure Container Registry
# resource "azurerm_role_assignment" "aks_acr" {
#   principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
#   role_definition_name             = "AcrPull"
#   scope                            = azurerm_container_registry.acr.id
#   skip_service_principal_aad_check = true
# }

