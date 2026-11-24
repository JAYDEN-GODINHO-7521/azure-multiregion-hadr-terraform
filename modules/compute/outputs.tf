output "cluster_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.kv_workload.client_id
}

output "workload_identity_principal_id" {
  value = azurerm_user_assigned_identity.kv_workload.principal_id
}