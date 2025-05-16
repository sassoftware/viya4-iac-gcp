// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"fmt"
	"test/helpers"
	"testing"
)

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanDefaults(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)

	tests := map[string]helpers.TestCase{
		"k8sVersionTest": {
			Expected:          variables["kubernetes_version"],
			ResourceMapName:   "module.gke.google_container_cluster.primary",
			AttributeJsonPath: "{$.min_master_version}",
		},
		"nameTest": {
			Expected:          fmt.Sprintf("%s-gke", variables["prefix"]),
			ResourceMapName:   "module.gke.google_container_cluster.primary",
			AttributeJsonPath: "{$.name}",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
