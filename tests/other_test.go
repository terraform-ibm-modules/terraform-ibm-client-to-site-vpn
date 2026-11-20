// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"fmt"
	"testing"

	"github.com/IBM/go-sdk-core/v5/core"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"

	"github.com/stretchr/testify/assert"
)

func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:          t,
		TerraformDir:     "examples/basic",
		CloudInfoService: sharedInfoSvc,
		Prefix:           "cts-basic",
		/*
		 Comment out the 'ResourceGroup' input to force this tests to create a unique resource group to ensure tests do
		 not clash. This is due to the fact that an auth policy may already exist in this resource group since we are
		 re-using a permanent secrets-manager instance, and the auth policy cannot be scoped to an exact VPN instance
		 ID. This is due to the face that the VPN can't be provisioned without the cert from secrets manager, but it
		 can't grab the cert from secrets manager until the policy is created. By using a new resource group, the auth
		 policy will not already exist since this module scopes auth policies by resource group.
		*/
		//ResourceGroup: resourceGroup,
		TerraformVars: map[string]interface{}{
			"vpn_client_access_group_users": []string{"GoldenEye.Operations@ibm.com"},
			"secrets_manager_guid":          permanentResources["secretsManagerGuid"],
			"secrets_manager_region":        permanentResources["secretsManagerRegion"],
			"certificate_template_name":     permanentResources["privateCertTemplateName"],
		},
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestAddonsDefaultConfiguration(t *testing.T) {

	t.Parallel()
	overrideInputMappings := true
	options := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:               t,
		Prefix:                "cts-vpn",
		QuietMode:             false,                  // Suppress logs except on failure
		OverrideInputMappings: &overrideInputMappings, // service_plan on SM dependency is also set via reference from parent secrets_manager_service_plan; allow explicit __NULL__ to take precedence
	})

	// use unique resource group to prevent s2s auth policy clash
	uniqueResourceGroup := generateUniqueResourceGroupName(options.Prefix)

	options.AddonConfig = cloudinfo.NewAddonConfigTerraform(
		options.Prefix,
		"deploy-arch-ibm-client-to-site-vpn",
		"fully-configurable",
		map[string]interface{}{
			// prefix must be set explicitly: it is shared (reference_version) with the private cert dependency and engine,
			// which name the template "<prefix>-template". Without this it defaults to a random value.
			"prefix":                       options.Prefix,
			"region":                       "eu-de",
			"secrets_manager_service_plan": "trial",
			// use unique resource group to prevent s2s auth policy clash
			"existing_resource_group_name": uniqueResourceGroup,
		},
	)

	//	use existing secrets manager instance to prevent hitting 20 trial instance limit in account
	options.AddonConfig.Dependencies = []cloudinfo.AddonConfig{
		{
			OfferingName:   "deploy-arch-ibm-secrets-manager",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"existing_secrets_manager_crn":         permanentResources["privateOnlySecMgrCRN"],
				"service_plan":                         "__NULL__", // no plan value needed when using existing SM
				"skip_secrets_manager_iam_auth_policy": true,       // since using an existing Secrets Manager instance, attempting to re-create auth policy can cause conflicts if the policy already exists
				"secret_groups":                        []string{}, // passing empty array for secret groups as default value is creating general group and it will cause conflicts as we are using an existing SM
			},
		},
		// private cert v1.12.16+ no longer maps cert_template from the private cert engine, so it must be provided.
		{
			OfferingName:   "deploy-arch-secrets-manager-private-cert",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"cert_template": fmt.Sprintf("%s-template", options.Prefix),
			},
		},
		// Disable target / route creation to prevent hitting quota in account
		{
			OfferingName:   "deploy-arch-ibm-cloud-monitoring",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_metrics_routing_to_cloud_monitoring": false,
			},
		},
		{
			OfferingName:   "deploy-arch-ibm-activity-tracker",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_activity_tracker_event_routing_to_cloud_logs": false,
			},
		},
		// Use the permanent App Configuration instance to prevent creating a new one on each run
		{
			OfferingName:   "deploy-arch-ibm-scc-workload-protection",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"app_config_crn": permanentResources["app_config_crn"],
			},
			Enabled: core.BoolPtr(true),
		},
		{
			OfferingName:   "deploy-arch-ibm-apprapp",
			OfferingFlavor: "fully-configurable",
			Enabled:        core.BoolPtr(false),
		},
	}

	var err = sharedInfoSvc.WithNewResourceGroup(uniqueResourceGroup, func() error {
		return options.RunAddonTest()
	})
	require.NoError(t, err)

}

func generateUniqueResourceGroupName(baseName string) string {
	id := uuid.New().String()[:8]
	return fmt.Sprintf("%s-%s", baseName, id)
}
