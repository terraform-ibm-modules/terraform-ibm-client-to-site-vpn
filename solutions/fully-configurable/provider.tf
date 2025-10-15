provider "ibm" {
  ibmcloud_api_key      = var.ibmcloud_api_key
  region                = (var.existing_secrets_manager_instance_crn != null) ? module.existing_sm_crn_parser[0].region : local.vpc_region
  alias                 = "ibm-sm"
  visibility            = var.provider_visibility
  private_endpoint_type = (var.provider_visibility == "private" && local.vpc_region == "ca-mon") ? "vpe" : null
}

provider "ibm" {
  ibmcloud_api_key      = var.ibmcloud_api_key
  region                = local.vpc_region
  visibility            = var.provider_visibility
  private_endpoint_type = (var.provider_visibility == "private" && local.vpc_region == "ca-mon") ? "vpe" : null
}
