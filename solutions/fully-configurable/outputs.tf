##############################################################################
# Outputs
##############################################################################

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.resource_group_name
}

output "resource_group_id" {
  description = "Resource group ID"
  value       = module.resource_group.resource_group_id
}

output "vpn_server_certificate_secret_id" {
  description = "ID of the client to site vpn server certificate secret stored in Secrets Manager"
  value       = var.existing_secrets_manager_cert_crn == null ? module.secrets_manager_private_certificate[0].secret_id : module.existing_secrets_manager_cert_crn_parser[0].service_instance
}

output "vpn_server_certificate_secret_crn" {
  description = "CRN of the client to site vpn server certificate secret stored in Secrets Manager"
  value       = local.secrets_manager_cert_crn
}

output "vpn_id" {
  description = "Client to Site VPN ID"
  value       = module.vpn.vpn_server_id
}

output "next_steps_text" {
  value       = "Now, you can access your VPN server."
  description = "Next steps text"
}

output "next_step_primary_label" {
  value       = "Go to client-to-site VPN server"
  description = "Primary label"
}

output "next_step_primary_url" {
  value       = "https://cloud.ibm.com/infrastructure/network/vpnServers/${module.existing_vpc_crn_parser.region}~${module.vpn.vpn_server_id}/overview"
  description = "Primary URL for the Client-to-Site VPN instance"
}

output "next_step_secondary_label" {
  value       = "Learn more about client-to-site VPN servers"
  description = "Secondary label"
}

output "next_step_secondary_url" {
  value       = "https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-client-to-site-overview&interface=ui"
  description = "Secondary URL"
}
