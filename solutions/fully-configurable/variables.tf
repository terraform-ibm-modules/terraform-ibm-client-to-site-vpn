variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key to deploy resources."
  sensitive   = true
}

variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To skip using a prefix, set this value to `null` or an empty string. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

  validation {
    # - null and empty string is allowed
    # - Must not contain consecutive hyphens (--): length(regexall("--", var.prefix)) == 0
    # - Starts with a lowercase letter: [a-z]
    # - Contains only lowercase letters (a–z), digits (0–9), and hyphens (-)
    # - Must not end with a hyphen (-): [a-z0-9]
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }

  validation {
    # must not exceed 16 characters in length
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the resources. If not provided the default resource group will be used."
  default     = null
}

##############################################################################
# Secrets Manager resources
##############################################################################

variable "existing_secrets_manager_instance_crn" {
  type        = string
  description = "The CRN of existing secrets manager where the certificate to use for the VPN is stored or where the new private certificate will be created. [Learn more](https://cloud.ibm.com/docs/secrets-manager?topic=secrets-manager-getting-started)"
  default     = null
}

variable "existing_secrets_manager_cert_crn" {
  type        = string
  description = "The CRN of existing secrets manager private certificate to use to create VPN. If the value is null, then new private certificate is created. [Learn more](https://cloud.ibm.com/docs/secrets-manager?topic=secrets-manager-certificates&interface=ui)"
  default     = null

  validation {
    condition     = var.existing_secrets_manager_cert_crn == null ? var.private_cert_engine_config_template_name != null && var.private_cert_engine_config_root_ca_common_name != null : true
    error_message = "Set 'private_cert_engine_config_root_ca_common_name' and 'private_cert_engine_config_template_name' input variables if a 'existing_secrets_manager_cert_crn' input variable is not set"
  }

  validation {
    condition     = var.existing_secrets_manager_cert_crn != null ? var.private_cert_engine_config_template_name == null && var.private_cert_engine_config_root_ca_common_name == null : true
    error_message = "'private_cert_engine_config_root_ca_common_name' and 'private_cert_engine_config_template_name' input variables can not be set if a 'existing_secrets_manager_cert_crn' input variable is already set"
  }
}

variable "existing_secrets_manager_secret_group_id" {
  type        = string
  description = "The ID of existing secrets manager secret group used for new created certificate. If the value is null, then new secrets manager secret group is created. [Learn more](https://cloud.ibm.com/docs/secrets-manager?topic=secrets-manager-secret-groups&interface=ui)"
  default     = null
}

variable "private_cert_engine_config_root_ca_common_name" {
  type        = string
  description = "A fully qualified domain name or host domain name for the certificate to be created. Only used when `existing_secrets_manager_cert_crn` input variable is `null`. [Learn more](https://cloud.ibm.com/docs/secrets-manager?topic=secrets-manager-private-certificates&interface=ui)"
  default     = null
}

variable "private_cert_engine_config_template_name" {
  type        = string
  description = "The name of the Certificate Template to create for a private certificate secret engine. When `existing_secrets_manager_cert_crn` input variable is `null`, then it has to be the existing template name that exists in the private cert engine. [Learn more](https://cloud.ibm.com/docs/secrets-manager?topic=secrets-manager-private-certificates&interface=ui)"
  default     = null
}

variable "client_dns_server_ips" {
  type        = list(string)
  description = "DNS server addresses that will be provided to VPN clients connected to this VPN server"
  default     = []
  nullable    = false
}

variable "enable_split_tunneling" {
  type        = bool
  description = "Enables split tunnel mode for the Client to Site VPN server"
  default     = true
}

variable "client_idle_timeout" {
  type        = number
  description = "The seconds a VPN client can be idle before this VPN server will disconnect it. Default set to 30m (1800 secs). Specify 0 to prevent the server from disconnecting idle clients."
  default     = 1800
}

variable "skip_secrets_manager_iam_auth_policy" {
  type        = bool
  description = "Specifies whether to create an IAM authorization policy with the SecretsReader role, allowing communication between all VPN servers (scoped to the specified resource group) and the given Secrets Manager instance. Currently, it is not possible to scope the policy to the exact VPN server ID, as the policy must be created before the instance exists. This is because the policy uses the certificate stored in Secrets Manager during the provisioning process."
  default     = false
}

##############################################################################
# client-to-site VPN
##############################################################################

variable "vpn_name" {
  type        = string
  description = "The name of the VPN. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  default     = "cts-vpn"
  nullable    = false
}

variable "enable_username_auth" {
  type        = bool
  description = "Set to true to use IAM usernames for client authentication to this VPN server. For more information, see https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-client-environment-setup"
  default     = true
}

variable "enable_certificate_auth" {
  type        = bool
  description = "Set to true to enable client certificate authentication for this VPN server. You must specify certificates using the client_cert_crns input variable. For more information, see https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-client-environment-setup"
  default     = false
}

variable "vpn_subnet_cidr_zone_1" {
  type        = string
  description = "The CIDR range to use for subnet creation from the first zone in the region (or zone specified in the 'vpn_zone_1' input variable). Ensure it's not conflicting with any existing subnets. Must be set if 'existing_subnet_ids' input variable is not set."
  default     = "10.10.40.0/24"
}

variable "vpn_subnet_cidr_zone_2" {
  type        = string
  description = "The CIDR range to use for subnet creation from the second zone in the region (or zone specified in the 'vpn_zone_2' input variable). Ensure it's not conflicting with any existing subnets. Must be set if 'existing_subnet_ids' input variable is not set."
  default     = null
}

variable "remote_cidr" {
  type        = string
  description = "The source CIDR block to use for creating ACL rule and security group (if add_security_group input variable is set to true). By default the deny all inbound and outbound ACL rule is created. Must be set if 'existing_subnet_ids' input variable is not set."
  default     = "0.0.0.0/0"
}

variable "add_security_group" {
  type        = bool
  description = "Add security group to a new VPN?"
  default     = true
}

variable "vpn_client_access_group_users" {
  description = "The list of users in the Client to Site VPN Access Group"
  type        = list(string)
  default     = []
  nullable    = false
}

variable "access_group_name" {
  type        = string
  description = "The name of the IAM Access Group to create if the 'create_policy' input variable is `true`."
  default     = "client-to-site-vpn-access-group"
}

variable "create_policy" {
  description = "Whether to create a new access group (using the value of the 'access_group_name' input variable) with a VPN Client role."
  type        = bool
  default     = true
}

variable "vpn_server_routes" {
  type        = list(string)
  description = "A map of server routes to be added to created VPN server. By default the route (166.8.0.0/14) for PaaS IBM Cloud backbone is added (mostly used to give access to the Kube master endpoints) and 161.26.0.0/16 (IaaS)."
  default     = ["10.0.0.0/8"]
  nullable    = false
}

variable "existing_vpc_crn" {
  type        = string
  description = "Crn of the existing VPC in which the VPN infrastructure will be created."
}

variable "vpn_zone_1" {
  type        = string
  description = "Optionally specify the first zone where the VPN gateway will be created. If not specified, it will default to the first zone in the region."
  default     = null
}

variable "vpn_zone_2" {
  type        = string
  description = "Optionally specify the second zone where the VPN gateway will be created. If not specified, it will default to the second zone in the region."
  default     = null
}

variable "existing_subnet_ids" {
  type        = list(string)
  description = "Optionally pass a list of existing subnet ids (supports a maximum of 2) to use for the client-to-site VPN. If no subnets passed, new subnets will be created using the CIDR ranges specified in the 'vpn_subnet_cidr_zone_1' and 'vpn_subnet_cidr_zone_2' input variables. On existing subnets no ACL rules are set."
  nullable    = false
  default     = []

  validation {
    error_message = "The existing_subnet_ids input variable supports a maximum of 2 subnets."
    condition     = (length(var.existing_subnet_ids) == 0 || length(var.existing_subnet_ids) < 3)
  }

  validation {
    condition     = length(var.existing_subnet_ids) <= 0 ? var.vpn_subnet_cidr_zone_1 != null && var.remote_cidr != null : true
    error_message = "Set 'vpn_subnet_cidr_zone_1' and 'remote_cidr input variables' if 'existing_subnet_ids' input variable is not set."
  }

}

variable "client_ip_pool" {
  type        = string
  description = "The VPN client IPv4 address pool, expressed in CIDR format. The request must not overlap with any existing address prefixes in the VPC or any of the following reserved address ranges: - 127.0.0.0/8 (IPv4 loopback addresses) - 161.26.0.0/16 (IBM services) - 166.8.0.0/14 (Cloud Service Endpoints) - 169.254.0.0/16 (IPv4 link-local addresses) - 224.0.0.0/4 (IPv4 multicast addresses). The prefix length of the client IP address pool's CIDR must be between /9 (8,388,608 addresses) and /22 (1024 addresses). A CIDR block that contains twice the number of IP addresses that are required to enable the maximum number of concurrent connections is recommended."
  default     = "10.0.0.0/20"
  nullable    = false
}

variable "vpn_client_access_acl_ids" {
  type        = list(string)
  description = "List of existing ACL rule IDs to which VPN connection rules is added."
  default     = []
  nullable    = false
}

variable "existing_security_group_ids" {
  description = "The existing security groups ID to use for this VPN server. If unspecified, the VPC's default security group is used. To use existing security groups, the 'add_security_group' input variable must be set to 'false'"
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = length(var.existing_security_group_ids) > 0 ? var.add_security_group == false : true
    error_message = "When 'existing_security_group_ids' input variable is set, then 'add_security_group' input variable should be set to false."
  }
}

variable "vpn_route_action" {
  type        = string
  description = "The action to perform with a packet matching the VPN route. The same action will be applied to all routes."
  default     = "deliver"
  nullable    = false
}

variable "client_cert_crns" {
  type        = list(string)
  description = "List of client CRN certificates used for VPN authentication. Must not be empty if enable_certificate_auth is true."
  default     = []
  nullable    = false

  validation {
    condition     = var.enable_certificate_auth ? length(var.client_cert_crns) != 0 : true
    error_message = "client_cert_crns must not be empty when enable_certificate_auth is set to true."
  }

  validation {
    condition     = alltrue([for crn in var.client_cert_crns : can(regex("^crn:(.*:){3}secrets-manager:(.*:){2}[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}:secret:[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", crn))])
    error_message = "One or more client CRN certificates in the 'client_cert_crns' input are invalid."
  }
}

variable "protocol" {
  description = "The transport protocol to use for this VPN server. Allowable values are: udp, tcp"
  type        = string
  default     = "udp"
  validation {
    condition     = contains(["tcp", "udp"], var.protocol)
    error_message = "Protocol must be either 'tcp' or 'udp'."
  }
}

##############################################################################
# Provider
##############################################################################

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "private"
  nullable    = false

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}
