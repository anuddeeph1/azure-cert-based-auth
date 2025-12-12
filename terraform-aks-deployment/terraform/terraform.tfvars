# Environment Configuration
environment         = "dev"
location            = "centralindia"  # Fixed typo
resource_group_name = "rg-anudeep"

# AKS Cluster Configuration
cluster_name       = "aks-novartis-dev"
dns_prefix         = "aks-novartis-dev"
kubernetes_version = "1.33.5"  # Latest available version

# Default Node Pool Configuration
default_node_pool_name      = "systempool"
#default_node_pool_vm_size   = "Standard_D4as_v5"
default_node_pool_vm_size   = "Standard_B2s"
default_node_pool_count     = 1
default_node_pool_min_count = 1
default_node_pool_max_count = 1
default_node_pool_max_pods  = 100

# Network Configuration
network_plugin = "azure"
network_policy = "azure"
service_cidr   = "10.0.0.0/16"
dns_service_ip = "10.0.0.10"

# Feature Flags
enable_rbac          = true
enable_azure_policy  = true
enable_oms_agent     = true
enable_auto_scaling  = true
enable_user_node_pool = true  # ← ENABLED! Creates 2nd node pool

# User Node Pool Configuration (if enabled)
user_node_pool_name    = "userpool"
user_node_pool_vm_size = "Standard_B2s" 
#user_node_pool_vm_size = "Standard_D4as_v5"
user_node_pool_count   = 1

# Azure AD Admin Groups (Optional - add your Azure AD group object IDs)
# admin_group_object_ids = ["your-azure-ad-group-object-id"]

# Private Cluster Configuration
enable_private_cluster = true
private_dns_zone_id    = null  # Let Azure manage the private DNS zone

# Virtual Network Configuration
create_vnet            = true
vnet_name              = "vnet-aks-novartis-dev"
vnet_address_space     = ["10.1.0.0/16"]
subnet_name            = "snet-aks-nodes"
subnet_address_prefixes = ["10.1.0.0/20"]

# Tags
tags = {
  Project     = "Novartis-AKS"
  ManagedBy   = "Terraform"
  Environment = "Development"
  Owner       = "DevOps-Team"
  CostCenter  = "Engineering"
  CreatedBy   = "Terraform-Local"
#CreatedBy   = "Azure-DevOps-Pipeline"
}


# Enable Nirmata integration
enable_nirmata = true

# Nirmata API credentials
nirmata_token        = "GU4XLFKtCP1w8v3R3rv30qD6PLEOR7dbtYtM2yck5AzTfJOGSnmxTH3X0DVeEF1xSyr8qgmtbCjw9ki8ZKMJOw=="
nirmata_url          = "https://nirmata.io"

# Cluster registration in Nirmata
nirmata_cluster_name = "aks-novartis-dev"
nirmata_cluster_type = "default-add-ons"