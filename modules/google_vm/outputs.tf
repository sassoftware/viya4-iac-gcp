# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "private_ip" {
  value = google_compute_instance.google_vm.network_interface[0].network_ip
}

output "public_ip" {
  value = length(module.address.addresses) > 0 ? module.address.addresses[0] : null
}

output "admin_username" {
  value = var.vm_admin
}
