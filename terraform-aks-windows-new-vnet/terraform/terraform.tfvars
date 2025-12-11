# Environment Configuration
environment         = "dev"
location            = "centralindia"
resource_group_name = "rg-aks-windows"

# AKS Cluster Configuration
cluster_name       = "aks-win-cluster"  # Can't use "windows" in name!
dns_prefix         = "aks-win"
kubernetes_version = "1.33.5"

# Linux System Node Pool (Required for Windows clusters)
# Windows clusters MUST have a Linux system pool
linux_node_pool_name      = "linuxpool"
linux_node_pool_vm_size   = "Standard_B2s" # Small, just for system components
linux_node_pool_count     = 1
linux_node_pool_min_count = 1
linux_node_pool_max_count = 2

# Windows Node Pool (Your Windows applications)
enable_windows_node_pool    = true
windows_node_pool_name      = "wpool"
windows_node_pool_vm_size   = "Standard_B2s" # Adjust based on your quota
windows_node_pool_count     = 1
windows_node_pool_min_count = 1
windows_node_pool_max_count = 3

# Windows Admin Credentials
windows_admin_username = "azureuser"
# Password is auto-generated (see outputs)

# Network Configuration
network_plugin = "azure"
network_policy = "azure"
service_cidr   = "10.0.0.0/16"
dns_service_ip = "10.0.0.10"

# Virtual Network Configuration
create_vnet             = true
vnet_name               = "vnet-aks-windows"
vnet_address_space      = ["10.2.0.0/16"]
subnet_name             = "snet-aks-nodes"
subnet_address_prefixes = ["10.2.0.0/20"]

# Private Cluster Configuration
enable_private_cluster = true

# Feature Flags
enable_rbac         = true
enable_azure_policy = true
enable_oms_agent    = true
enable_auto_scaling = true

# Tags
tags = {
  Project     = "Novartis-AKS-Windows"
  ManagedBy   = "Terraform"
  Environment = "Development"
  Owner       = "DevOps-Team"
  CostCenter  = "Engineering"
  CreatedBy   = "Terraform-Local"
  OS          = "Windows"
}

