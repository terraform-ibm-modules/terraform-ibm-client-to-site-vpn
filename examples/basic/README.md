# Basic example creating a standalone VPN server

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=client-to-site-vpn-basic-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-client-to-site-vpn/tree/main/examples/basic"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


Requirements:
- An existing Secrets Manager instance configured with the private cert engine
- A Certificate Template in the Secrets Manager instance to use for private cert creation.

This example will:
 - Create a new resource group if one is not passed in.
 - Create a new secret group in the Secrets Manager instance provided.
 - Create a new private cert and place it in a secret in the newly created secret group.
 - Create a new VPC in the resource group and region provided.
 - Create a standalone VPN server

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
