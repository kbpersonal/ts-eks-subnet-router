variable "base64_encode" {
  description = "Whether to base64 encode the cloud-init data"
  type        = bool
  default     = true
}

variable "gzip" {
  description = "Whether to gzip the cloud-init data"
  type        = bool
  default     = false
}

variable "enable_ssh" {
  description = "Enable SSH access via Tailscale"
  type        = bool
  default     = false
}

variable "hostname" {
  description = "Hostname of the instance"
  type        = string
  default     = ""
}

variable "accept_dns" {
  description = "Accept DNS configuration from Tailscale"
  type        = bool
  default     = true
}

variable "accept_routes" {
  description = "Accept routes from Tailscale"
  type        = bool
  default     = false
}

variable "advertise_connector" {
  description = "Advertise this node as an app connector"
  type        = bool
  default     = false
}

variable "advertise_exit_node" {
  description = "Offer to be an exit node for internet traffic for the tailnet"
  type        = bool
  default     = false
}

variable "advertise_routes" {
  description = "Routes to advertise to other nodes"
  type        = list(string)
  default     = []
}

variable "exit_node" {
  description = "Tailscale exit node (IP or base name) for internet traffic"
  type        = string
  default     = ""
}

variable "exit_node_allow_lan_access" {
  description = "Allow direct access to the local network when routing traffic via an exit node"
  type        = bool
  default     = false
}

variable "force_reauth" {
  description = "force reauthentication"
  type        = bool
  default     = false
}

variable "json" {
  description = "output in JSON format"
  type        = bool
  default     = false
}

variable "login_server" {
  description = "base URL of control server"
  type        = string
  default     = "https://controlplane.tailscale.com"
}

variable "operator" {
  description = "Unix username to allow to operate on tailscaled without sudo"
  type        = string
  default     = ""
}

variable "reset" {
  description = "reset unspecified settings to their default values"
  type        = bool
  default     = false
}

variable "shields_up" {
  description = "don't allow incoming connections"
  type        = bool
  default     = false
}

variable "timeout" {
  description = "maximum amount of time to wait for tailscaled to enter a Running state"
  type        = string
  default     = "0s"
}

variable "netfilter_mode" {
  description = "netfilter mode"
  type        = string
  default     = "on"

  validation {
    condition     = contains(["on", "nodivert", "off"], var.netfilter_mode)
    error_message = "Allowed values for netfilter_mode are \"on\", \"nodivert\", or \"off\"."
  }
}

variable "snat_subnet_routes" {
  description = "source NAT traffic to local routes advertised with --advertise-routes"
  type        = bool
  default     = true
}

variable "stateful_filtering" {
  description = "apply stateful filtering to forwarded packets"
  type        = bool
  default     = false
}

variable "max_retries" {
  description = "maximum number of retries to connect to the control server"
  type        = number
  default     = 3
}

variable "retry_delay" {
  description = "delay in seconds between retries to connect to the control server"
  type        = number
  default     = 5
}

variable "additional_parts" {
  description = "Additional user defined part blocks for the cloudinit_config data source"
  type = list(object({
    filename     = string
    content_type = optional(string)
    content      = optional(string)
    merge_type   = optional(string)
  }))
  default = []
}

variable "track" {
  description = "Version of the Tailscale client to install"
  type        = string
  default     = "stable"
  validation {
    condition     = contains(["stable", "unstable"], var.track)
    error_message = "Allowed values for track are \"stable\", \"unstable\""
  }
}

variable "preauthorized" {
  default     = true
  type        = bool
  description = "Determines whether or not the machines authenticated by the key will be authorized for the tailnet by default."
}

variable "ephemeral" {
  default     = false
  type        = bool
  description = "Indicates if the key is ephemeral."
}

variable "reusable" {
  default     = false
  type        = bool
  description = "Indicates if the key is reusable or single-use."
}

variable "expiry" {
  default     = 7776000
  type        = number
  description = "The expiry of the auth key in seconds."
}

variable "primary_tag" {
  default     = null
  type        = string
  description = "The primary tag to apply to the Tailscale EC2 instance. Do not include the `tag:` prefix. This must match the OAuth client's tag."
}

variable "additional_tags" {
  default     = []
  type        = list(string)
  description = "Additional Tailscale tags to apply to the Tailscale EC2 instance in addition to `primary_tag`. These should not include the `tag:` prefix."
}