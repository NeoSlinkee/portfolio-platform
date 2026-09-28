locals {
  prefix    = "${var.name}-${var.location}"
  namespace = "portfolio"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = var.tags
}

# --- Networking ----------------------------------------------------------

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "nodes" {
  name                 = "snet-aks-nodes"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.nodes_subnet_cidr]
}

# Subnet-level NSG (free). AKS still manages its own NIC-level rules; this
# layer only admits web traffic from the internet to the ingress load balancer.
resource "azurerm_network_security_group" "nodes" {
  #checkov:skip=CKV_AZURE_160:Port 80 must stay open for Let's Encrypt HTTP-01 challenges; ingress-nginx redirects it to HTTPS.
  name                = "nsg-${local.prefix}-nodes"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  security_rule {
    name                       = "allow-web-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_ranges    = ["80", "443"]
  }
}

resource "azurerm_subnet_network_security_group_association" "nodes" {
  subnet_id                 = azurerm_subnet.nodes.id
  network_security_group_id = azurerm_network_security_group.nodes.id
}

# --- Cost guardrail ------------------------------------------------------
# Budgets are free. They alert, they do not stop spend, which is why the
# README says to `terraform destroy` as soon as a demo is over.

resource "azurerm_consumption_budget_resource_group" "this" {
  count = length(var.budget_alert_emails) > 0 ? 1 : 0

  name              = "budget-${local.prefix}"
  resource_group_id = azurerm_resource_group.this.id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
           start_date = var.budget_start_date
  }

  dynamic "notification" {
    for_each = [50, 80, 100]
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThanOrEqualTo"
      threshold_type = "Actual"
      contact_emails = var.budget_alert_emails
    }
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}
