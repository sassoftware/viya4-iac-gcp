# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "kube_config" {
  value = var.create_static_kubeconfig ? local.kube_config_sa : local.kube_config_provider
}
