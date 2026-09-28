data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "this" {
  #checkov:skip=CKV_AZURE_115:Private cluster needs a jump host or VPN; API access is restricted by authorized IP ranges instead.
  #checkov:skip=CKV_AZURE_4:Container Insights needs Log Analytics, which is billed per GB. Prometheus/Grafana in-cluster is used instead.
  #checkov:skip=CKV_AZURE_117:Customer-managed disk encryption needs Key Vault + Disk Encryption Set; platform-managed keys are used.
  #checkov:skip=CKV_AZURE_227:Host encryption must be enabled per subscription and is not available on all VM sizes.
  #checkov:skip=CKV_AZURE_226:Ephemeral OS disks need a VM with enough cache; Standard_B2s does not qualify.
  #checkov:skip=CKV_AZURE_170:Paid SLA tier (Standard) is not justified for a portfolio site; Free tier is used on purpose.
  #checkov:skip=CKV_AZURE_232:Single node pool keeps cost minimal; a dedicated system pool would double node cost.
  #checkov:skip=CKV_AZURE_6:API server IP allow-list is set via var.api_server_authorized_ip_ranges and applied at deploy time.
  #checkov:skip=CKV_AZURE_172:Secrets Store CSI driver is not used; the site has no secrets.
  name                = "aks-${local.prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "aks-${var.name}"
  kubernetes_version  = var.kubernetes_version

  # Free control plane: no uptime SLA, no charge for the API server.
  sku_tier = "Free"

  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  # Identity and access: Entra ID + Azure RBAC, no static kubeconfig admin.
  local_account_disabled            = true
  role_based_access_control_enabled = true
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  # Workload identity lets pods and GitHub Actions use short-lived tokens.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Azure Policy add-on (free) enforces baseline pod security in-cluster.
  azure_policy_enabled = true

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  default_node_pool {
    name                         = "system"
    vm_size                      = var.node_vm_size
    node_count                   = var.node_count
    vnet_subnet_id               = azurerm_subnet.nodes.id
    max_pods                     = 50
    os_sku                       = "AzureLinux"
    only_critical_addons_enabled = false
    temporary_name_for_rotation  = "systemtmp"

    upgrade_settings {
      max_surge = "1"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Azure CNI Overlay with the Cilium dataplane: pods get IPs from an overlay
  # range (no VNet exhaustion) and NetworkPolicies are enforced by eBPF.
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
    load_balancer_sku   = "standard"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [kubernetes_version, default_node_pool[0].orchestrator_version]
  }
}
