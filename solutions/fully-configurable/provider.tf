provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = module.existing_sm_crn_parser.region
  alias            = "ibm-sm"
  visibility            = var.provider_visibility
  private_endpoint_type = (var.provider_visibility == "private" && var.region == "ca-mon") ? "vpe" : null
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = local.vpc_region
  visibility            = var.provider_visibility
  private_endpoint_type = (var.provider_visibility == "private" && var.region == "ca-mon") ? "vpe" : null
}