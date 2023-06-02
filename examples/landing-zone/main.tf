locals {
  vpn_gateway_name = format("%s-%s", var.prefix, var.base_vpn_gateway_name)
  sm_guid          = var.existing_sm_instance_guid == null ? ibm_resource_instance.secrets_manager[0].guid : var.existing_sm_instance_guid
  sm_region        = var.existing_sm_instance_region == null ? var.region : var.existing_sm_instance_region
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Secrets Manager Instance
##############################################################################

resource "ibm_resource_instance" "secrets_manager" {
  count             = var.existing_sm_instance_guid == null ? 1 : 0
  name              = "${var.prefix}-sm-instance"
  service           = "secrets-manager"
  plan              = var.sm_service_plan
  location          = local.sm_region
  resource_group_id = module.resource_group.resource_group_id
  timeouts {
    create = "20m" # Extending provisioning time to 20 minutes
  }
  provider = ibm.ibm-sm
}

# Add the private cert engine to the Secret Manager instance
module "private_secret_engine" {
  depends_on                = [ibm_resource_instance.secrets_manager]
  count                     = var.existing_sm_instance_guid == null ? 1 : 0
  source                    = "git::https://github.com/terraform-ibm-modules/terraform-ibm-secrets-manager-private-cert-engine?ref=v1.0.0"
  secrets_manager_guid      = local.sm_guid
  region                    = local.sm_region
  root_ca_name              = var.root_ca_name
  root_ca_common_name       = var.root_ca_common_name
  root_ca_max_ttl           = "8760h"
  intermediate_ca_name      = var.intermediate_ca_name
  certificate_template_name = var.certificate_template_name
  providers = {
    ibm = ibm.ibm-sm
  }
}

# Best practice, create a secret group
resource "ibm_sm_secret_group" "secret_group" {
  name        = "${var.prefix}-certificates-secret-group"
  description = "secret group used for private certificates"
  region      = local.sm_region
  instance_id = local.sm_guid
  provider    = ibm.ibm-sm
}


module "secrets_manager_private_certificate" {
  depends_on             = [module.private_secret_engine]
  source                 = "git::https://github.com/terraform-ibm-modules/terraform-ibm-secrets-manager-private-cert.git?ref=v1.0.0"
  cert_name              = "${var.prefix}-cts-vpn-private-cert"
  cert_description       = "an example private cert"
  cert_template          = var.certificate_template_name
  cert_secrets_group_id  = ibm_sm_secret_group.secret_group.secret_group_id
  cert_common_name       = "goldeneye.appdomain.cloud"
  secrets_manager_guid   = local.sm_guid
  secrets_manager_region = local.sm_region
  providers = {
    ibm = ibm.ibm-sm
  }
}

##############################################################################
# Deploy client-to-site in a dedicated subnet in the management Landing Zone VPC
##############################################################################

locals {
  zone = var.vpn_zone != null ? var.vpn_zone : "${var.region}-1" # hardcode to first zone in region
}


resource "ibm_is_vpc_address_prefix" "client_to_site_address_prefixes" {
  name = "${var.prefix}-client-to-site-address-prefixes"
  zone = local.zone
  vpc  = var.vpc_id != null ? var.vpc_id : local.vpc_id
  cidr = var.vpn_subnet_cidr
}

resource "ibm_is_network_acl" "client_to_site_vpn_acl" {
  name = "${var.prefix}-client-to-site-acl"
  vpc  = var.vpc_id != null ? var.vpc_id : local.vpc_id
  rules {
    name        = "outbound"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
    udp {
      source_port_min = 443
      source_port_max = 443
    }
  }
  rules {
    name        = "inbound"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    udp {
      port_min = 443
      port_max = 443
    }
  }
}

resource "ibm_is_subnet" "client_to_site_subnet" {
  depends_on      = [ibm_is_vpc_address_prefix.client_to_site_address_prefixes]
  name            = "${var.prefix}-client-to-site-subnet"
  vpc             = var.vpc_id != null ? var.vpc_id : local.vpc_id
  ipv4_cidr_block = var.vpn_subnet_cidr
  zone            = local.zone
  network_acl     = ibm_is_network_acl.client_to_site_vpn_acl.id
}

module "vpn" {
  source                        = "../.."
  server_cert_crn               = module.secrets_manager_private_certificate.secret_crn
  vpn_gateway_name              = local.vpn_gateway_name
  resource_group_id             = module.resource_group.resource_group_id
  subnet_ids                    = [ibm_is_subnet.client_to_site_subnet.id]
  create_policy                 = var.create_policy
  vpn_client_access_group_users = var.vpn_client_access_group_users
  access_group_name             = "${var.prefix}-${var.access_group_name}"
  secrets_manager_id            = local.sm_guid
  vpn_server_routes             = var.vpn_server_routes
}

module "client_to_site_sg" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-security-group?ref=v1.0.0"
  add_ibm_cloud_internal_rules = true
  vpc_id                       = var.vpc_id != null ? var.vpc_id : local.vpc_id
  resource_group               = module.resource_group.resource_group_id
  security_group_name          = "${var.prefix}-client-to-site-sg"
  security_group_rules = [{
    name      = "allow-all-inbound"
    direction = "inbound"
    remote    = "0.0.0.0/0"
  }]
  target_ids = [module.vpn.vpn_server_id]
}

##############################################################################
# Update network ACLs to allow traffic from VPN client IPs
##############################################################################

locals {
  client_cidr         = "10.0.0.0/20" # Default in client-to-site
  management_vpc_name = var.landing_zone_prefix != null ? "${var.landing_zone_prefix}-management-vpc" : null


  # Validate vpc input
  # Validation approach based on https://stackoverflow.com/a/66682419
  vpc_input_validate_condition = (var.landing_zone_prefix != null && var.vpc_id == null) || (var.landing_zone_prefix == null && var.vpc_id != null)
  vpc_input_validate_msg       = "Either 'landing-zone-prefix' or 'vpc_id' variable must be set."
  # tflint-ignore: terraform_unused_declarations
  vpc_input_validate_check = regex("^${local.vpc_input_validate_msg}$", (local.vpc_input_validate_condition ? local.vpc_input_validate_msg : ""))

  # Management VPC subnets
  vpc_id             = var.vpc_id != null ? var.vpc_id : data.ibm_is_vpc.management_vpc_by_name[0].identifier
  management_subnets = var.vpc_id != null ? data.ibm_is_vpc.management_vpc_by_id[0] : data.ibm_is_vpc.management_vpc_by_name[0]

}

data "ibm_is_vpc" "management_vpc_by_id" {
  count      = var.adjust_landing_zone_acls && var.vpc_id != null ? 1 : 0
  identifier = var.vpc_id
  #name = local.management_vpc_name
}

data "ibm_is_vpc" "management_vpc_by_name" {
  count = var.adjust_landing_zone_acls && local.management_vpc_name != null ? 1 : 0
  name  = local.management_vpc_name
}

data "ibm_is_subnet" "one_subnet" {
  count      = var.adjust_landing_zone_acls ? 1 : 0
  identifier = local.management_subnets.subnets[1].id
}

data "ibm_is_network_acl_rules" "existing_inbound_rules" {
  count       = var.adjust_landing_zone_acls ? 1 : 0
  network_acl = data.ibm_is_subnet.one_subnet[0].network_acl
  direction   = "inbound"
}

data "ibm_is_network_acl_rules" "existing_outbound_rules" {
  count       = var.adjust_landing_zone_acls ? 1 : 0
  network_acl = data.ibm_is_subnet.one_subnet[0].network_acl
  direction   = "outbound"
}

resource "ibm_is_network_acl_rule" "allow_vpn_inbound" {
  count       = var.adjust_landing_zone_acls ? 1 : 0
  network_acl = data.ibm_is_subnet.one_subnet[0].network_acl
  before      = data.ibm_is_network_acl_rules.existing_inbound_rules[0].rules[0].rule_id
  name        = "inbound"
  action      = "allow"
  source      = local.client_cidr
  destination = var.landing_zone_network_cidr
  direction   = "inbound"
}

resource "ibm_is_network_acl_rule" "allow_vpn_outbound" {
  count       = var.adjust_landing_zone_acls ? 1 : 0
  network_acl = data.ibm_is_subnet.one_subnet[0].network_acl
  before      = data.ibm_is_network_acl_rules.existing_outbound_rules[0].rules[0].rule_id
  name        = "outbound"
  action      = "allow"
  source      = var.landing_zone_network_cidr
  destination = local.client_cidr
  direction   = "outbound"
}
