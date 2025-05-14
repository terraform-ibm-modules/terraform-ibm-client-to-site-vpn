##############################################################################
# Account variables
##############################################################################

variable "resource_group_id" {
  description = "ID of the resource group to use when creating the VPN server"
  type        = string
}

##############################################################################
# VPN server variables
##############################################################################

variable "vpn_gateway_name" {
  type        = string
  description = "The user-defined name for the VPN server. If unspecified, the name will be a hyphenated list of randomly-selected words. Names must be unique within the VPC the VPN server is serving."
}

variable "client_ip_pool" {
  type        = string
  description = "The VPN client IPv4 address pool, expressed in CIDR format. The request must not overlap with any existing address prefixes in the VPC or any of the following reserved address ranges: - 127.0.0.0/8 (IPv4 loopback addresses) - 161.26.0.0/16 (IBM services) - 166.8.0.0/14 (Cloud Service Endpoints) - 169.254.0.0/16 (IPv4 link-local addresses) - 224.0.0.0/4 (IPv4 multicast addresses). The prefix length of the client IP address pool's CIDR must be between /9 (8,388,608 addresses) and /22 (1024 addresses). A CIDR block that contains twice the number of IP addresses that are required to enable the maximum number of concurrent connections is recommended."
  default     = "10.0.0.0/20"
}

variable "client_dns_server_ips" {
  type        = list(string)
  description = "DNS server addresses that will be provided to VPN clients connected to this VPN server"
  default     = []
}

variable "client_auth_methods" {
  type        = list(string)
  description = "The methods used to authenticate VPN clients to this VPN server. Allowable values are: certificate, username. For more information, see https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-client-environment-setup"
  default     = ["username"]
  validation {
    error_message = "Allowed values are username and certificate."
    condition     = alltrue([for method in var.client_auth_methods : contains(["username", "certificate"], method)])
  }
  validation {
    error_message = "Each value (username or certificate) may appear at most once (no duplicates allowed)"
    condition     = length(var.client_auth_methods) == length(distinct(var.client_auth_methods))
  }
}

variable "client_idle_timeout" {
  type        = number
  description = "The seconds a VPN client can be idle before this VPN server will disconnect it. Default set to 30m (1800 secs). Specify 0 to prevent the server from disconnecting idle clients."
  default     = 1800
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to provision this VPN server in. List must have at least 1 subnet ID for standalone VPN and at least 2 subnet IDs for the High Availability mode."
  validation {
    error_message = "The list should have at least 1 subnet ID and maximum of 2 subnet IDs"
    condition     = (length(var.subnet_ids) > 0 && length(var.subnet_ids) < 3)
  }
}

variable "server_cert_crn" {
  type        = string
  description = "CRN of a secret in Secrets Manager that contains the certificate to use for the VPN"
}

variable "client_cert_crns" {
  type        = list(string)
  description = "List of client CRN certificates used for VPN authentication."
  default     = []
  nullable    = false

  validation {
    condition     = anytrue([for method in var.client_auth_methods : method == "certificate"]) ? length(var.client_cert_crns) != 0 : true
    error_message = "client_cert_crns must not be empty when client_auth_methods includes 'certificate'."
  }

  validation {
    condition     = alltrue([for crn in var.client_cert_crns : can(regex("^crn:(.*:){3}secrets-manager:(.*:){2}[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}:secret:[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", crn))])
    error_message = "One or more client CRN certificates in the 'client_cert_crns' input are invalid."
  }
}

variable "enable_split_tunneling" {
  type        = bool
  description = "Enables split tunnel mode for the Client to Site VPN server"
  default     = true
}

variable "existing_security_group_ids" {
  description = "The existing security groups ID to use for this VPN server. If unspecified, the VPC's default security group is used"
  type        = list(string)
  default     = []
  nullable    = false
}

##############################################################################
# Auth related variables
##############################################################################

variable "create_policy" {
  description = "Set to true to create a new access group (using the value of var.access_group_name) with a VPN Client role"
  type        = bool
  default     = true

  validation {
    condition     = var.create_policy ? var.access_group_name != null : true
    error_message = "Value for 'access_group_name' input variable must not be null if 'create_policy' input variable is true"
  }
}

variable "vpn_client_access_group_users" {
  description = "List of users to optionally add to the Client to Site VPN Access Group if var.create_policy is true"
  type        = list(string)
  default     = []
}

variable "access_group_name" {
  type        = string
  description = "Name of the IAM Access Group to create if var.create_policy is true"
  default     = "client-to-site-vpn-access-group"
}

variable "skip_secrets_manager_iam_auth_policy" {
  type        = bool
  description = "Specifies whether to create an IAM authorization policy with the SecretsReader role, allowing communication between all VPN servers (scoped to the specified resource group) and the given Secrets Manager instance. Currently, it is not possible to scope the policy to the exact VPN server ID, as the policy must be created before the instance exists. This is because the policy uses the certificate stored in Secrets Manager during the provisioning process."
  default     = false
}

##############################################################################
# VPN server route variables
##############################################################################

variable "vpn_server_routes" {
  type = map(object({
    destination = string
    action      = string
  }))
  description = "Map of server routes to be added to created VPN server."
  default     = {}
}
