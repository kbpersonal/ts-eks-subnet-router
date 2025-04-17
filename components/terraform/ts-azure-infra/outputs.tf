output "cluster_name" {
  value     = local.cluster_name
  sensitive = true
}

output "hostname" {
  value     = local.hostname
  sensitive = true
}

output "vnet_cidr" {
  value     = local.vnet_cidr
  sensitive = true
}

output "aks_service_ipv4_cidr" {
  value     = local.aks_service_ipv4_cidr
  sensitive = true
}

output "ssh_private_key_path" {
  value     = local.ssh_private_key_path
  sensitive = true
}

output "resource_group_name" {
  value     = azurerm_resource_group.main.name
  sensitive = true
}

output "client_public_ip" {
  value     = azurerm_public_ip.main.ip_address
  sensitive = true
}

output "aks_cluster_host" {
  value     = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive = true
}

output "aks_cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "aks_cluster_name" {
  value     = azurerm_kubernetes_cluster.main.name
  sensitive = true
}

output "oauth_client_id" {
  value     = local.oauth_client_id
  sensitive = true
}

output "oauth_client_secret" {
  value     = local.oauth_client_secret
  sensitive = true
}

output "Message" {
  description = "Instructions for configuring your environment after Terraform apply."
  value = <<-EOT
Next Steps:
1. Configure your kubeconfig for kubectl by running:
   az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name} --overwrite-existing

2. Test SSH to the VM's public IP:
   ssh -i ${local.ssh_private_key_path} ubuntu@${azurerm_public_ip.main.ip_address}

Happy deploying <3
EOT
}
