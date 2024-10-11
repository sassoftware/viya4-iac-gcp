# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Terraform Registry : https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/netapp_volume
# GitHub Repository  : https://github.com/terraform-google-modules
#

resource "google_netapp_storage_pool" "my-tf-pool" {
  name          = "${var.name}-storage-pool"
  location      = var.region
  service_level = "PREMIUM"
  capacity_gib  = 2048
  network       = data.google_compute_network.my-vpc.id
}

resource "google_netapp_volume" "my-nfsv3-volume" {
  location         = var.region
  name             = "${var.name}-volume"
  capacity_gib     = 1024 # Size can be up to space available in pool
  share_name       = "my-nfsv3-volume"
  storage_pool     = google_netapp_storage_pool.my-tf-pool.name
  protocols        = ["NFSV4.1"]
  unix_permissions = "0777"
  export_policy {
    # Order of rules matters! Go from most specific to most generic
    rules {
      access_type     = "READ_WRITE"
      allowed_clients = "10.10.10.17"
      has_root_access = true
      nfsv3           = true
    }
    rules {
      access_type     = "READ_ONLY"
      allowed_clients = "10.10.0.0/16"
      has_root_access = false
      nfsv3           = true
    }
  }
}
