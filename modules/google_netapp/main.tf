# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Terraform Registry : https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/netapp_volume
# GitHub Repository  : https://github.com/terraform-google-modules
#

resource "google_netapp_storage_pool" "netapp-tf-pool" {
  name          = "${var.prefix}-netapp-storage-pool"
  location      = var.region
  service_level = var.service_level
  capacity_gib  = var.capacity_gib
  network       = var.network
}

resource "google_netapp_volume" "netapp-nfs-volume" {
  location         = var.region
  name             = "${var.prefix}-netapp-volume"
  capacity_gib     = 1024 # Size can be up to space available in pool
  share_name       = var.volume_path
  storage_pool     = google_netapp_storage_pool.netapp-tf-pool.name
  protocols        = var.protocols
  unix_permissions = "0777"
  export_policy {
    rules {
      access_type     = "READ_WRITE"
      allowed_clients = var.allowed_clients
      has_root_access = true
      nfsv4           = true
    }
  }

  depends_on = [
    google_netapp_storage_pool.netapp-tf-pool
  ]
}
