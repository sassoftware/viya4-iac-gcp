// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Test the default variables when using the sample-input-defaults.tfvars file
// with storage_type set to "ha". This should engage the Azure NetApp Files module,
// with the default values as tested herein.
func TestPlanNetApp(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "net-app"
	variables["storage_type"] = "ha"
	variables["storage_type_backend"] = "netapp"

	tests := map[string]helpers.TestCase{
		"poolExists": {
			Expected:          `nil`,
			ResourceMapName:   "module.google_netapp[0].google_netapp_storage_pool.netapp-tf-pool",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"poolServiceLevel": {
			Expected:          `PREMIUM`,
			ResourceMapName:   "module.google_netapp[0].google_netapp_storage_pool.netapp-tf-pool",
			AttributeJsonPath: "{$.service_level}",
		},
		"capactityGib": {
			Expected:          `2048`,
			ResourceMapName:   "module.google_netapp[0].google_netapp_storage_pool.netapp-tf-pool",
			AttributeJsonPath: "{$.capacity_gib}",
		},
		"volumeExists": {
			Expected:          `nil`,
			ResourceMapName:   "module.google_netapp[0].google_netapp_volume.netapp-nfs-volume",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"volumeProtocols": {
			Expected:          `["NFSV3"]`,
			ResourceMapName:   "module.google_netapp[0].google_netapp_volume.netapp-nfs-volume",
			AttributeJsonPath: "{$.protocols}",
			AssertFunction:    assert.Contains,
		},
		"shareName": {
			Expected:          `net-app-export`,
			ResourceMapName:   "module.google_netapp[0].google_netapp_volume.netapp-nfs-volume",
			AttributeJsonPath: "{$.share_name}",
		},
		"communityNetappPrivateIpAllocEnabled": {
			Expected:          `nil`,
			ResourceMapName:   "module.google_netapp[0].google_compute_global_address.private_ip_alloc[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"communityNetappRouteUpdatesEnabled": {
			Expected:          `nil`,
			ResourceMapName:   "module.google_netapp[0].google_compute_network_peering_routes_config.route_updates[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"communityNetappServiceNetworkingConnectionEnabled": {
			Expected:          `nil`,
			ResourceMapName:   "module.google_netapp[0].google_service_networking_connection.default[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
	}

	plan := helpers.GetPlan(t, variables)
	helpers.RunTests(t, tests, plan)
}
