# Environment Configuration
environment         = "dev"
location            = "centralindia"
resource_group_name = "rg-anudeep" # Use existing resource group!

# AKS Cluster Configuration
cluster_name       = "aks-win-cluster" # Can't use "windows" in name!
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
windows_node_pool_name      = "win01"        # Max 6 chars for Windows pools!
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
#create_vnet             = true
#vnet_name               = "vnet-aks-windows"
#vnet_address_space      = ["10.2.0.0/16"]
#subnet_name             = "snet-aks-nodes"
#subnet_address_prefixes = ["10.2.0.0/20"]
create_vnet             = false                   # Use existing VNet!
vnet_name               = "vnet-aks-novartis-dev" # Existing VNet name
vnet_address_space      = ["10.1.0.0/16"]         # Existing VNet address
subnet_name             = "snet-aks-windows"      # New subnet for Windows cluster
subnet_address_prefixes = ["10.1.32.0/20"]        # Non-overlapping (10.1.0.0/20 already used)


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

# Enable Nirmata integration
enable_nirmata = true

# Nirmata API credentials
nirmata_token        = "GU4XLFKtCP1w8v3R3rv30qD6PLEOR7dbtYtM2yck5AzTfJOGSnmxTH3X0DVeEF1xSyr8qgmtbCjw9ki8ZKMJOw=="
nirmata_url          = "https://nirmata.io"

# Cluster registration in Nirmata
nirmata_cluster_name = "aks-novartis-dev"
nirmata_cluster_type = "default-add-ons"
