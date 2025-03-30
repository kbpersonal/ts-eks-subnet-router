variable "name" {
  description = "List of the cluster names"
  type        = list(string)
}

variable "regions" {
  description = "List of regions to deploy the VPCs and their respective EKS clusters"
  type        = list(string)
}

variable "ssh_keyname" {
  description = "AWS SSH Keypair Name"
  type        = list(string)
}

variable "tags" {
  description = "Map of user-defined common tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidrs" {
  description = "List of AWS VPC CIDRs for each cluster"
  type        = list(string)
}

variable "cluster_service_ipv4_cidr" {
  description = "List of Kubernetes Service CIDRs for each cluster"
  type        = list(string)
  default     = ["10.40.0.0/16","10.40.0.0/16"]
}

variable "cluster_version" {
  description = "Kubernetes version for all clusters"
  type        = string
  default     = "1.32"
}

variable "desired_size" {
  description = "Desired number of cluster nodes in all clusters"
  type        = string
  default     = "2"
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
  description = "List of Tailscale Machine hostname of the EC2 SR instances"
  type        = list(string)
}

variable "advertise_routes" {
  description = "List of user-defined CIDR blocks to advertise via Tailscale for each cluster in addition to the EKS private subnets"
  type        = list(list(string))  # A list of lists of CIDRs, one for each cluster
  default     = []
}