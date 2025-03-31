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

variable "name" {
  description = "Name of cluster"
  type        = string
}

variable "region" {
  description = "AWS Region of cluster"
  type        = string
}

variable "ssh_keyname" {
  description = "AWS SSH Keypair Name"
  type        = string
}

variable "tags" {
  description = "Map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "AWS VPC CIDR"
  type        = string
}

variable "cluster_service_ipv4_cidr" {
  description = "Kubernetes Service CIDR"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for this cluster"
  type        = string
}

variable "desired_size" {
  description = "Number of cluster nodes"
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
  description = "Tailscale Machine hostname of the EC2 instance"
  type        = string
}

variable "advertise_routes" {
  description = "List of CIDR blocks to advertise via Tailscale in addition to the EKS private subnets"
  type        = list(string)
  default     = []
}