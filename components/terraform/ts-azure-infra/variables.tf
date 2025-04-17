variable "tenant" {
  description = "Name of the user/tenant for the Atmos Stack"
  type        = string
}

variable "environment" {
  description = "Short-form name of the region for the Atmos Stack"
  type        = string
}

variable "stage" {
  description = "Name of stage"
  type        = string
}

variable "cluster_name" {
  description = "Name of cluster"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key to use for VM access."
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key for remote provisioner and SSH access."
  type        = string
}

variable "tags" {
  description = "Map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "vnet_cidr" {
  description = "Azure VNet CIDR"
  type        = string
}

variable "aks_service_ipv4_cidr" {
  description = "Kubernetes Service CIDR"
  type        = string
}

variable "cluster_vm_size" {
  description = "VM size for AKS node pool"
  type        = string
}

variable "vm_size" {
  description = "VM size for Tailscale VM"
  type        = string
}

variable "aks_version" {
  description = "Kubernetes version for this cluster"
  type        = string
}

variable "min_count" {
  description = "Number of cluster nodes"
  type        = string
}

variable "node_count" {
  description = "Number of cluster nodes"
  type        = string
}

variable "max_count" {
  description = "Number of cluster nodes"
  type        = string
}

variable "cluster_outbound_type" {
  description = <<-EOF
  Outbound type for the cluster: Choose between 'userAssignedNATGateway' 
  to force hard NAT or 'loadBalancer' to get easy NAT.
  EOF
  type        = string
}

variable "oauth_client_id" {
  type        = string
  sensitive   = true
  description = <<-EOF
  The OAuth application's ID when using OAuth client credentials.
  Can be set via the TAILSCALE_OAUTH_CLIENT_ID environment variable.
  Both 'oauth_client_id' and 'oauth_client_secret' must be set.
  EOF
}

variable "oauth_client_secret" {
  type        = string
  sensitive   = true
  description = <<-EOF
  (Sensitive) The OAuth application's secret when using OAuth client credentials.
  Can be set via the TAILSCALE_OAUTH_CLIENT_SECRET environment variable.
  Both 'oauth_client_id' and 'oauth_client_secret' must be set.
  EOF
}

variable "hostname" {
  description = "Tailscale Machine hostname of the VM instance"
  type        = string
}

variable "advertise_routes" {
  description = "List of CIDR blocks to advertise via Tailscale in addition to the AKS private subnets"
  type        = list(string)
  default     = []
}
