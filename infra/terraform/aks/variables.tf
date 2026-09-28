variable "subscription_id" {
  description = "Azure subscription to deploy into."
  type        = string
  default     = null
}

variable "name" {
  description = "Base name used for all resources."
  type        = string
  default     = "portfolio"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.name))
    error_message = "Use 3-20 lowercase letters, digits or hyphens."
  }
}

variable "location" {
  description = "Azure region. South Africa North keeps latency low for a Johannesburg audience."
  type        = string
  default     = "southafricanorth"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version (null = current default)."
  type        = string
  default     = null
}

variable "node_vm_size" {
  description = "VM size for the single system node pool. Smallest size AKS supports for system pools."
  type        = string
  default     = "Standard_B2s"
}

variable "node_count" {
  description = "Number of nodes. 1 keeps cost minimal; use 2+ for real availability."
  type        = number
  default     = 1
}

variable "vnet_cidr" {
  description = "Address space for the cluster VNet."
  type        = string
  default     = "10.10.0.0/16"
}

variable "nodes_subnet_cidr" {
  description = "Subnet for AKS nodes."
  type        = string
  default     = "10.10.1.0/24"
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDRs allowed to reach the Kubernetes API (your public IP as x.x.x.x/32). Empty = unrestricted."
  type        = list(string)
  default     = []
}

variable "github_repository" {
  description = "owner/repo allowed to deploy via GitHub Actions OIDC (no stored secrets)."
  type        = string
  default     = "NeoSlinkee/portfolio-platform"
}

variable "budget_amount" {
  description = "Monthly budget in the billing currency. Alerts fire at 50%, 80% and 100%."
  type        = number
  default     = 10
}

variable "budget_start_date" {
  description = "First day of the month the budget starts (Azure requires the 1st of a month, RFC3339)."
  type        = string
  default     = "2026-10-01T00:00:00Z"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-01T00:00:00Z$", var.budget_start_date))
    error_message = "Use the first day of a month, e.g. 2026-10-01T00:00:00Z."
  }
}

variable "budget_alert_emails" {
  description = "Addresses that receive budget alerts."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    project    = "portfolio-platform"
    managed_by = "terraform"
    owner      = "NeoSlinkee"
  }
}
