output "resource_group_name" {
  description = "Name of the resource group"
  #value       = azurerm_resource_group.aks.name
  value       = data.azurerm_resource_group.aks.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_kubeconfig" {
  description = "Kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_private_fqdn" {
  description = "Private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.private_fqdn
}

output "aks_is_private" {
  description = "Whether the cluster is private"
  value       = azurerm_kubernetes_cluster.aks.private_cluster_enabled
}

output "aks_cluster_endpoint" {
  description = "Endpoint for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "windows_admin_username" {
  description = "Windows admin username"
  value       = var.windows_admin_username
}

output "windows_admin_password" {
  description = "Windows admin password"
  value       = random_password.windows_admin.result
  sensitive   = true
}

output "linux_node_pool_name" {
  description = "Name of the Linux system node pool"
  value       = var.linux_node_pool_name
}

output "windows_node_pool_name" {
  description = "Name of the Windows node pool"
  value       = var.enable_windows_node_pool ? var.windows_node_pool_name : "Not enabled"
}

output "vnet_id" {
  #description = "ID of the virtual network"
  #value       = var.create_vnet ? azurerm_virtual_network.aks[0].id : null
  description = "ID of the virtual network (shared with Linux cluster)"
  value       = data.azurerm_virtual_network.aks.id
}

output "subnet_id" {
  #description = "ID of the AKS subnet"
  #value       = var.create_vnet ? azurerm_subnet.aks[0].id : null
  #description = "ID of the Windows AKS subnet"
  #value       = azurerm_subnet.aks_windows.id
  description = "ID of the Windows AKS subnet (existing)"
  value       = data.azurerm_subnet.aks_windows.id
}

output "aks_version" {
  description = "Kubernetes version of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kubernetes_version
}

output "aks_node_resource_group" {
  description = "Auto-generated resource group for AKS nodes"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "connect_command" {
  description = "Command to connect to the AKS cluster"
  #value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${azurerm_kubernetes_cluster.aks.name}"
  value       = "az aks get-credentials --resource-group ${data.azurerm_resource_group.aks.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}

output "deployment_summary" {
  description = "Deployment summary"
  value       = <<-EOT
    ========================================
    AKS Windows Cluster Deployment Summary
    ========================================
    
    Cluster Name:      ${azurerm_kubernetes_cluster.aks.name}
    Resource Group:    ${data.azurerm_resource_group.aks.name} (shared with Linux cluster)
    Location:          ${data.azurerm_resource_group.aks.location}
    Kubernetes:        ${azurerm_kubernetes_cluster.aks.kubernetes_version}
    Private Cluster:   ${azurerm_kubernetes_cluster.aks.private_cluster_enabled}
    
    Node Pools:
    -----------
    1. Linux System Pool:  ${var.linux_node_pool_name} (${var.linux_node_pool_vm_size})
    2. Windows User Pool:  ${var.enable_windows_node_pool ? var.windows_node_pool_name : "Not enabled"} (${var.windows_node_pool_vm_size})
    
    Access:
    -------
    ${azurerm_kubernetes_cluster.aks.private_cluster_enabled ? "⚠️  PRIVATE CLUSTER - Access via Jump Box or VPN" : "Public cluster - direct access"}
    
    Connect: az aks get-credentials --resource-group ${data.azurerm_resource_group.aks.name} --name ${azurerm_kubernetes_cluster.aks.name}
    
    Windows Admin:
    --------------
    Username: ${var.windows_admin_username}
    Password: (see 'terraform output windows_admin_password')
    
    ========================================
  EOT
}

