output "resource_group_name" {
  description = "Resource group holding everything (delete it to remove all cost)."
  value       = azurerm_resource_group.this.name
}

output "cluster_name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "oidc_issuer_url" {
  description = "Cluster OIDC issuer, for workload identity federation."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "github_actions_client_id" {
  description = "Set as the AZURE_CLIENT_ID repository variable for the deploy workflow."
  value       = azurerm_user_assigned_identity.github_deploy.client_id
}

output "tenant_id" {
  description = "Set as the AZURE_TENANT_ID repository variable."
  value       = data.azurerm_client_config.current.tenant_id
}

output "get_credentials_command" {
  description = "Fetch a kubeconfig (uses your Entra ID login)."
  value       = "az aks get-credentials -g ${azurerm_resource_group.this.name} -n ${azurerm_kubernetes_cluster.this.name} && kubelogin convert-kubeconfig -l azurecli"
}
