# General Variables
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "centralindia"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-aks-windows"
}

# AKS Cluster Variables
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-windows-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.33.5"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "aks-windows"
}

# Linux System Node Pool Variables (Required for Windows clusters)
variable "linux_node_pool_name" {
  description = "Name of the Linux system node pool (required for Windows)"
  type        = string
  default     = "linuxpool"
}

variable "linux_node_pool_vm_size" {
  description = "VM size for Linux system node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "linux_node_pool_count" {
  description = "Number of nodes in Linux system pool"
  type        = number
  default     = 1
}

variable "linux_node_pool_min_count" {
  description = "Minimum nodes for Linux pool"
  type        = number
  default     = 1
}

variable "linux_node_pool_max_count" {
  description = "Maximum nodes for Linux pool"
  type        = number
  default     = 3
}

# Windows Node Pool Variables
variable "enable_windows_node_pool" {
  description = "Enable Windows node pool"
  type        = bool
  default     = true
}

variable "windows_node_pool_name" {
  description = "Name of the Windows node pool"
  type        = string
  default     = "winpool"
}

variable "windows_node_pool_vm_size" {
  description = "VM size for Windows node pool"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "windows_node_pool_count" {
  description = "Number of nodes in Windows pool"
  type        = number
  default     = 2
}

variable "windows_node_pool_min_count" {
  description = "Minimum nodes for Windows pool"
  type        = number
  default     = 1
}

variable "windows_node_pool_max_count" {
  description = "Maximum nodes for Windows pool"
  type        = number
  default     = 5
}

# Windows Admin Credentials
variable "windows_admin_username" {
  description = "Admin username for Windows nodes"
  type        = string
  default     = "azureuser"
}

# Note: Password will be generated automatically with random provider

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

# Virtual Network Variables
variable "create_vnet" {
  description = "Create a new virtual network"
  type        = bool
  default     = true
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "vnet-aks-windows"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "subnet_name" {
  description = "Name of the AKS subnet"
  type        = string
  default     = "snet-aks-nodes"
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the AKS subnet"
  type        = list(string)
  default     = ["10.2.0.0/20"]
}

# Private Cluster Configuration
variable "enable_private_cluster" {
  description = "Enable private cluster (private API server endpoint)"
  type        = bool
  default     = true
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
  description = "Enable auto-scaling"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Novartis-AKS-Windows"
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

