locals {
  # There is a provider bug generating "module-metadata.json" where variable value is not access directly.
  # https://github.com/IBM-Cloud/terraform-config-inspect/issues/19
  subnet_ids = var.subnet_ids
}

# IAM Service to Service Authorization
# More info: https://cloud.ibm.com/docs/vpc?topic=vpc-client-to-site-authentication#creating-iam-service-to-service
# NOTE: The auth policy cannot be scoped to the exact VPN server instance ID because the VPN can't be provisioned
# without the cert from secrets manager, but it cant grab the cert from secrets manager until the policy is created.
resource "ibm_iam_authorization_policy" "policy" {
  count                       = var.skip_secrets_manager_iam_auth_policy ? 0 : 1
  source_service_name         = "is"
  source_resource_type        = "vpn-server"
  source_resource_group_id    = var.resource_group_id
  target_service_name         = "secrets-manager"
  target_resource_instance_id = module.sm_crn_parser.service_instance
  roles                       = ["SecretsReader"]
  description                 = "Allow all VPN server instances in the resource group ${var.resource_group_id} to read from the Secrets Manager instance with ID ${module.sm_crn_parser.service_instance}"
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  depends_on = [ibm_iam_authorization_policy.policy]

  create_duration = "30s"
}

module "sm_crn_parser" {
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.server_cert_crn
}

# Access groups
# More info: https://cloud.ibm.com/docs/vpc?topic=vpc-create-iam-access-group
resource "ibm_iam_access_group" "cts_vpn_access_group" {
  count       = var.create_policy ? 1 : 0
  name        = var.access_group_name
  description = "Access group for the Client to Site VPN"
}

resource "ibm_iam_access_group_policy" "cts_vpn_access_group_policy" {
  count           = var.create_policy ? 1 : 0
  access_group_id = ibm_iam_access_group.cts_vpn_access_group[0].id
  roles           = ["VPN Client"]
  resources {
    service = "is"
  }
}

resource "ibm_iam_access_group_members" "cts_vpn_access_group_users" {
  count           = var.create_policy && length(var.vpn_client_access_group_users) > 0 ? 1 : 0
  access_group_id = ibm_iam_access_group.cts_vpn_access_group[0].id
  ibm_ids         = var.vpn_client_access_group_users
}

# Client to Site VPN
resource "ibm_is_vpn_server" "vpn" {
  certificate_crn = var.server_cert_crn
  client_authentication {
    method            = var.client_auth_methods
    identity_provider = var.client_auth_methods == "username" ? "iam" : null
  }
  client_idle_timeout    = var.client_idle_timeout
  client_ip_pool         = var.client_ip_pool
  client_dns_server_ips  = var.client_dns_server_ips
  enable_split_tunneling = var.enable_split_tunneling
  name                   = var.vpn_gateway_name
  subnets                = local.subnet_ids
  resource_group         = var.resource_group_id
  security_groups        = length(var.existing_security_group_ids) > 0 ? var.existing_security_group_ids : null
}

resource "ibm_is_vpn_server_route" "server_route" {
  depends_on = [
    ibm_iam_authorization_policy.policy
  ]
  for_each    = var.vpn_server_routes
  vpn_server  = ibm_is_vpn_server.vpn.vpn_server
  destination = each.value.destination
  action      = each.value.action
  name        = each.key
}
