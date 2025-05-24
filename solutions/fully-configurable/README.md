# Cloud automation for Client to Site VPN

This solution supports provisioning and configuring the following infrastructure:

- A secrets manager secret group, if one is not passed in.
- A private certificate, if one is not passed in.
- `client-to-site-subnet-1` and `client-to-site-subnet-2` subnets in the existing VPC, if `existing_subnet_ids` input variable is empty array.
- A network ACL on these subnets grants the access according to the `remote_cidr` input variable. By default the deny all inbound and outbound ACL rule is created.
- Security group that allows incoming requests from source defined with `remote_cidr` input variable. The `add_security_group` input variable must be set to `true`
- A client to site VPN gateway

![cts-fully-configurable-da](../../reference-architectures/cts-fully-configurable-da.svg)

**Important:** Because this solution contains a provider configuration and is not compatible with the `for_each`, `count`, and `depends_on` arguments, do not call this solution from one or more other modules. For more information about how resources are associated with provider configurations with multiple modules, see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers).

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.78.3 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.13.1 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_client_to_site_sg"></a> [client\_to\_site\_sg](#module\_client\_to\_site\_sg) | terraform-ibm-modules/security-group/ibm | 2.7.0 |
| <a name="module_existing_secrets_manager_cert_crn_parser"></a> [existing\_secrets\_manager\_cert\_crn\_parser](#module\_existing\_secrets\_manager\_cert\_crn\_parser) | terraform-ibm-modules/common-utilities/ibm//modules/crn-parser | 1.1.0 |
| <a name="module_existing_sm_crn_parser"></a> [existing\_sm\_crn\_parser](#module\_existing\_sm\_crn\_parser) | terraform-ibm-modules/common-utilities/ibm//modules/crn-parser | 1.1.0 |
| <a name="module_existing_vpc_crn_parser"></a> [existing\_vpc\_crn\_parser](#module\_existing\_vpc\_crn\_parser) | terraform-ibm-modules/common-utilities/ibm//modules/crn-parser | 1.1.0 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | terraform-ibm-modules/resource-group/ibm | 1.2.0 |
| <a name="module_secrets_manager_private_certificate"></a> [secrets\_manager\_private\_certificate](#module\_secrets\_manager\_private\_certificate) | terraform-ibm-modules/secrets-manager-private-cert/ibm | 1.3.3 |
| <a name="module_secrets_manager_secret_group"></a> [secrets\_manager\_secret\_group](#module\_secrets\_manager\_secret\_group) | terraform-ibm-modules/secrets-manager-secret-group/ibm | 1.3.6 |
| <a name="module_vpn"></a> [vpn](#module\_vpn) | ../.. | n/a |

### Resources

| Name | Type |
|------|------|
| [ibm_is_network_acl.client_to_site_vpn_acl](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.78.3/docs/resources/is_network_acl) | resource |
| [ibm_is_network_acl_rule.inbound_acl_rules_subnet1](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.78.3/docs/resources/is_network_acl_rule) | resource |
| [ibm_is_network_acl_rule.outbound_acl_rules_subnet1](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.78.3/docs/resources/is_network_acl_rule) | resource |
| [ibm_is_security_group_target.sg_target](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.78.3/docs/resources/is_security_group_target) | resource |
| [ibm_is_subnet.client_to_site_subnet_zone_1](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.78.3/docs/resources/is_subnet) | resource |
| [ibm_is_subnet.client_to_site_subnet_zone_2](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.78.3/docs/resources/is_subnet) | resource |
| [ibm_is_vpc_address_prefix.client_to_site_address_prefixes_zone_1](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.78.3/docs/resources/is_vpc_address_prefix) | resource |
| [ibm_is_vpc_address_prefix.client_to_site_address_prefixes_zone_2](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.78.3/docs/resources/is_vpc_address_prefix) | resource |
| [time_sleep.wait_for_security_group](https://registry.terraform.io/providers/hashicorp/time/0.13.1/docs/resources/sleep) | resource |
| [ibm_is_network_acl.existing_acls](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.78.3/docs/data-sources/is_network_acl) | data source |
| [ibm_is_subnet.existing_subnets](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.78.3/docs/data-sources/is_subnet) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_group_name"></a> [access\_group\_name](#input\_access\_group\_name) | The name of the IAM Access Group to create if the 'create\_policy' input variable is `true`. | `string` | `"client-to-site-vpn-access-group"` | no |
| <a name="input_add_security_group"></a> [add\_security\_group](#input\_add\_security\_group) | Add security group to a new VPN? | `bool` | `true` | no |
| <a name="input_client_cert_crns"></a> [client\_cert\_crns](#input\_client\_cert\_crns) | List of client CRN certificates used for VPN authentication. Must not be empty if enable\_certificate\_auth is true. | `list(string)` | `[]` | no |
| <a name="input_client_dns_server_ips"></a> [client\_dns\_server\_ips](#input\_client\_dns\_server\_ips) | DNS server addresses that will be provided to VPN clients connected to this VPN server | `list(string)` | `[]` | no |
| <a name="input_client_idle_timeout"></a> [client\_idle\_timeout](#input\_client\_idle\_timeout) | The seconds a VPN client can be idle before this VPN server will disconnect it. Default set to 30m (1800 secs). Specify 0 to prevent the server from disconnecting idle clients. | `number` | `1800` | no |
| <a name="input_client_ip_pool"></a> [client\_ip\_pool](#input\_client\_ip\_pool) | The VPN client IPv4 address pool, expressed in CIDR format. The request must not overlap with any existing address prefixes in the VPC or any of the following reserved address ranges: - 127.0.0.0/8 (IPv4 loopback addresses) - 161.26.0.0/16 (IBM services) - 166.8.0.0/14 (Cloud Service Endpoints) - 169.254.0.0/16 (IPv4 link-local addresses) - 224.0.0.0/4 (IPv4 multicast addresses). The prefix length of the client IP address pool's CIDR must be between /9 (8,388,608 addresses) and /22 (1024 addresses). A CIDR block that contains twice the number of IP addresses that are required to enable the maximum number of concurrent connections is recommended. | `string` | `"10.0.0.0/20"` | no |
| <a name="input_create_policy"></a> [create\_policy](#input\_create\_policy) | Whether to create a new access group (using the value of the 'access\_group\_name' input variable) with a VPN Client role. | `bool` | `true` | no |
| <a name="input_enable_certificate_auth"></a> [enable\_certificate\_auth](#input\_enable\_certificate\_auth) | Set to true to enable client certificate authentication for this VPN server. You must specify certificates using the client\_cert\_crns input variable. For more information, see https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-client-environment-setup | `bool` | `false` | no |
| <a name="input_enable_split_tunneling"></a> [enable\_split\_tunneling](#input\_enable\_split\_tunneling) | Enables split tunnel mode for the Client to Site VPN server | `bool` | `true` | no |
| <a name="input_enable_username_auth"></a> [enable\_username\_auth](#input\_enable\_username\_auth) | Set to true to use IAM usernames for client authentication to this VPN server. For more information, see https://cloud.ibm.com/docs/vpc?topic=vpc-vpn-client-environment-setup | `bool` | `true` | no |
| <a name="input_existing_resource_group_name"></a> [existing\_resource\_group\_name](#input\_existing\_resource\_group\_name) | The name of a an existing resource group in which to provision resources to. | `string` | `"Default"` | no |
| <a name="input_existing_secrets_manager_cert_crn"></a> [existing\_secrets\_manager\_cert\_crn](#input\_existing\_secrets\_manager\_cert\_crn) | The CRN of existing secrets manager private certificate to use to create VPN. If the value is null, then new private certificate is created. | `string` | `null` | no |
| <a name="input_existing_secrets_manager_instance_crn"></a> [existing\_secrets\_manager\_instance\_crn](#input\_existing\_secrets\_manager\_instance\_crn) | The CRN of existing secrets manager where the certificate to use for the VPN is stored or where the new private certificate will be created. | `string` | n/a | yes |
| <a name="input_existing_secrets_manager_secret_group_id"></a> [existing\_secrets\_manager\_secret\_group\_id](#input\_existing\_secrets\_manager\_secret\_group\_id) | The ID of existing secrets manager secret group used for new created certificate. If the value is null, then new secrets manager secret group is created. | `string` | `null` | no |
| <a name="input_existing_security_group_ids"></a> [existing\_security\_group\_ids](#input\_existing\_security\_group\_ids) | The existing security groups ID to use for this VPN server. If unspecified, the VPC's default security group is used. To use existing security groups, the 'add\_security\_group' input variable must be set to 'false' | `list(string)` | `[]` | no |
| <a name="input_existing_subnet_ids"></a> [existing\_subnet\_ids](#input\_existing\_subnet\_ids) | Optionally pass a list of existing subnet ids (supports a maximum of 2) to use for the client-to-site VPN. If no subnets passed, new subnets will be created using the CIDR ranges specified in the 'vpn\_subnet\_cidr\_zone\_1' and 'vpn\_subnet\_cidr\_zone\_2' input variables. On existing subnets no ACL rules are set. | `list(string)` | `[]` | no |
| <a name="input_existing_vpc_crn"></a> [existing\_vpc\_crn](#input\_existing\_vpc\_crn) | Crn of the existing VPC in which the VPN infrastructure will be created. | `string` | n/a | yes |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud API key to deploy resources. | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). Must begin with a letter and contain only lowercase letters, numbers, and - characters. To not use any prefix value, you can set this value to `null` or an empty string. | `string` | n/a | yes |
| <a name="input_private_cert_engine_config_root_ca_common_name"></a> [private\_cert\_engine\_config\_root\_ca\_common\_name](#input\_private\_cert\_engine\_config\_root\_ca\_common\_name) | A fully qualified domain name or host domain name for the certificate to be created. Only used when `existing_secrets_manager_cert_crn` input variable is `null`. | `string` | `null` | no |
| <a name="input_private_cert_engine_config_template_name"></a> [private\_cert\_engine\_config\_template\_name](#input\_private\_cert\_engine\_config\_template\_name) | The name of the Certificate Template to create for a private certificate secret engine. When `existing_secrets_manager_cert_crn` input variable is `null`, then it has to be the existing template name that exists in the private cert engine. | `string` | `null` | no |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | The transport protocol to use for this VPN server. Allowable values are: udp, tcp | `string` | `"udp"` | no |
| <a name="input_provider_visibility"></a> [provider\_visibility](#input\_provider\_visibility) | Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints). | `string` | `"private"` | no |
| <a name="input_remote_cidr"></a> [remote\_cidr](#input\_remote\_cidr) | The source CIDR block to use for creating ACL rule and security group (if add\_security\_group input variable is set to true). By default the deny all inbound and outbound ACL rule is created. Must be set if 'existing\_subnet\_ids' input variable is not set. | `string` | `"0.0.0.0/0"` | no |
| <a name="input_vpn_client_access_acl_ids"></a> [vpn\_client\_access\_acl\_ids](#input\_vpn\_client\_access\_acl\_ids) | List of existing ACL rule IDs to which VPN connection rules is added. | `list(string)` | `[]` | no |
| <a name="input_vpn_client_access_group_users"></a> [vpn\_client\_access\_group\_users](#input\_vpn\_client\_access\_group\_users) | The list of users in the Client to Site VPN Access Group | `list(string)` | `[]` | no |
| <a name="input_vpn_name"></a> [vpn\_name](#input\_vpn\_name) | The name of the VPN. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format. | `string` | `"cts-vpn"` | no |
| <a name="input_vpn_route_action"></a> [vpn\_route\_action](#input\_vpn\_route\_action) | The action to perform with a packet matching the VPN route. The same action will be applied to all routes. | `string` | `"deliver"` | no |
| <a name="input_vpn_server_routes"></a> [vpn\_server\_routes](#input\_vpn\_server\_routes) | A map of server routes to be added to created VPN server. By default the route (166.8.0.0/14) for PaaS IBM Cloud backbone is added (mostly used to give access to the Kube master endpoints) and 161.26.0.0/16 (IaaS). | `list(string)` | <pre>[<br/>  "10.0.0.0/8"<br/>]</pre> | no |
| <a name="input_vpn_subnet_cidr_zone_1"></a> [vpn\_subnet\_cidr\_zone\_1](#input\_vpn\_subnet\_cidr\_zone\_1) | The CIDR range to use for subnet creation from the first zone in the region (or zone specified in the 'vpn\_zone\_1' input variable). Ensure it's not conflicting with any existing subnets. Must be set if 'existing\_subnet\_ids' input variable is not set. | `string` | `"10.10.40.0/24"` | no |
| <a name="input_vpn_subnet_cidr_zone_2"></a> [vpn\_subnet\_cidr\_zone\_2](#input\_vpn\_subnet\_cidr\_zone\_2) | The CIDR range to use for subnet creation from the second zone in the region (or zone specified in the 'vpn\_zone\_2' input variable). Ensure it's not conflicting with any existing subnets. Must be set if 'existing\_subnet\_ids' input variable is not set. | `string` | `null` | no |
| <a name="input_vpn_zone_1"></a> [vpn\_zone\_1](#input\_vpn\_zone\_1) | Optionally specify the first zone where the VPN gateway will be created. If not specified, it will default to the first zone in the region. | `string` | `null` | no |
| <a name="input_vpn_zone_2"></a> [vpn\_zone\_2](#input\_vpn\_zone\_2) | Optionally specify the second zone where the VPN gateway will be created. If not specified, it will default to the second zone in the region. | `string` | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | Resource group ID |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name |
| <a name="output_vpn_id"></a> [vpn\_id](#output\_vpn\_id) | Client to Site VPN ID |
| <a name="output_vpn_server_certificate_secret_crn"></a> [vpn\_server\_certificate\_secret\_crn](#output\_vpn\_server\_certificate\_secret\_crn) | CRN of the client to site vpn server certificate secret stored in Secrets Manager |
| <a name="output_vpn_server_certificate_secret_id"></a> [vpn\_server\_certificate\_secret\_id](#output\_vpn\_server\_certificate\_secret\_id) | ID of the client to site vpn server certificate secret stored in Secrets Manager |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
