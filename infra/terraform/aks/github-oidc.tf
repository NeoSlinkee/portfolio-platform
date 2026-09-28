# GitHub Actions -> Azure without secrets: a user-assigned identity trusts
# tokens that GitHub issues for this repo's main branch, and is allowed to
# deploy into the portfolio namespace only (least privilege).

resource "azurerm_user_assigned_identity" "github_deploy" {
  name                = "id-${local.prefix}-github-deploy"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "github_main" {
  name                = "github-main"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.github_deploy.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repository}:ref:refs/heads/main"
}

# Needed to fetch cluster credentials (az aks get-credentials).
resource "azurerm_role_assignment" "github_cluster_user" {
  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_user_assigned_identity.github_deploy.principal_id
}

# Write access scoped to a single namespace, not the whole cluster.
resource "azurerm_role_assignment" "github_namespace_writer" {
  scope                = "${azurerm_kubernetes_cluster.this.id}/namespaces/${local.namespace}"
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = azurerm_user_assigned_identity.github_deploy.principal_id
}
