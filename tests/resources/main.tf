##############################################################################
# SLZ VPC
##############################################################################

module "landing_zone" {
  source  = "terraform-ibm-modules/landing-zone/ibm//patterns//vpc//module"
  version = "4.13.1"
  region  = var.region
  prefix  = var.prefix
  tags    = var.resource_tags
}
