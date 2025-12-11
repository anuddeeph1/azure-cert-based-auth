# General Variables
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-aks-novartis"
}

# AKS Cluster Variables
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-novartis-dev"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.28.3"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "aks-novartis"
}

# Node Pool Variables
variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "systempool"
}

variable "default_node_pool_vm_size" {
  description = "VM size for default node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "default_node_pool_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "default_node_pool_min_count" {
  description = "Minimum number of nodes for auto-scaling"
  type        = number
  default     = 2
}

variable "default_node_pool_max_count" {
  description = "Maximum number of nodes for auto-scaling"
  type        = number
  default     = 5
}

variable "default_node_pool_max_pods" {
  description = "Maximum number of pods per node"
  type        = number
  default     = 30
}

# Network Variables
variable "network_plugin" {
  description = "Network plugin to use (azure or kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy to use (calico or azure)"
  type        = string
  default     = "azure"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP address"
  type        = string
  default     = "10.0.0.10"
}

# Security Variables
variable "enable_rbac" {
  description = "Enable Role Based Access Control"
  type        = bool
  default     = true
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy for AKS"
  type        = bool
  default     = true
}

variable "enable_oms_agent" {
  description = "Enable OMS agent for monitoring"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for default node pool"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Novartis-AKS"
    ManagedBy   = "Terraform"
    Environment = "Development"
    Owner       = "DevOps-Team"
  }
}

# Azure AD Integration
variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for AKS admins"
  type        = list(string)
  default     = []
}

# Private Cluster Configuration
variable "enable_private_cluster" {
  description = "Enable private cluster (private API server endpoint)"
  type        = bool
  default     = true
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID for private cluster (optional)"
  type        = string
  default     = null
}

# Virtual Network Configuration
variable "create_vnet" {
  description = "Create a new virtual network for AKS"
  type        = bool
  default     = true
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "vnet-aks-novartis"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "subnet_name" {
  description = "Name of the AKS subnet"
  type        = string
  default     = "snet-aks-nodes"
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the AKS subnet"
  type        = list(string)
  default     = ["10.1.0.0/20"]
}

# Additional Node Pool (Optional)
variable "enable_user_node_pool" {
  description = "Enable additional user node pool"
  type        = bool
  default     = false
}

variable "user_node_pool_name" {
  description = "Name of the user node pool"
  type        = string
  default     = "userpool"
}

variable "user_node_pool_vm_size" {
  description = "VM size for user node pool"
  type        = string
  default     = "Standard_D8s_v3"
}

variable "user_node_pool_count" {
  description = "Number of nodes in user node pool"
  type        = number
  default     = 3
}

