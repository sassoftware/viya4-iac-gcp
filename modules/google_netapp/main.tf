# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Terraform Registry : https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/netapp_volume
# GitHub Repository  : https://github.com/terraform-google-modules
#

# Reserve compute address CIDR for NetApp Volumes to use
resource "google_compute_global_address" "private_ip_alloc" {
  count         = var.community_netapp_networking_components_enabled ? 1 : 0

  name          = "${var.network}-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = split("/", var.netapp_subnet_cidr)[0]
  prefix_length = split("/", var.netapp_subnet_cidr)[1]
  network       = var.network
}

# Create the PSA peering
resource "google_service_networking_connection" "default" {
  count         = var.community_netapp_networking_components_enabled ? 1 : 0

  network                 = var.network
  service                 = "netapp.servicenetworking.goog"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc[0].name]

  deletion_policy = "ABANDON"
}

# Modify the PSA Connection to allow import/export of custom routes
resource "google_compute_network_peering_routes_config" "route_updates" {
  count         = var.community_netapp_networking_components_enabled ? 1 : 0

  peering = google_service_networking_connection.default[0].peering
  network = var.network

  import_custom_routes = true
  export_custom_routes = true
}

resource "google_netapp_storage_pool" "netapp-tf-pool" {
  name          = "${var.prefix}-netapp-storage-pool"
  location      = var.region
  service_level = var.service_level
  capacity_gib  = var.capacity_gib
  network       = var.network

  # Always set primary zone when available; set replica zone only for multi-zone.
  zone         = local.primary_zone != null ? local.primary_zone : null
  replica_zone = local.is_multizone && local.replica_zone != null ? local.replica_zone : null

  lifecycle {
    ignore_changes = [network, zone, replica_zone]
  }
}

resource "google_netapp_volume" "netapp-nfs-volume" {
  location         = var.region
  name             = "${var.prefix}-netapp-volume"
  capacity_gib     = var.capacity_gib # Size can be up to space available in pool
  share_name       = var.volume_path
  storage_pool     = google_netapp_storage_pool.netapp-tf-pool.name
  protocols        = var.protocols
  unix_permissions = "0777"
  export_policy {
    rules {
      access_type     = "READ_WRITE"
      allowed_clients = var.allowed_clients
      has_root_access = true
      nfsv3           = contains(var.protocols, "NFSV3") ? true : false
      nfsv4           = contains(var.protocols, "NFSV4") ? true : false
      nfsv41          = contains(var.protocols, "NFSV4_1") ? true : false
    }
  }

  depends_on = [
    google_netapp_storage_pool.netapp-tf-pool,
    google_service_networking_connection.default
  ]
}

# Private DNS zone for zone-redundant NetApp endpoint
resource "google_dns_managed_zone" "netapp_private_zone" {
  count       = var.enable_netapp_dns && local.is_multizone ? 1 : 0
  name        = "${var.prefix}-netapp-dns-zone"
  dns_name    = "${var.netapp_dns_zone_name}."
  description = "Private DNS zone for zone-redundant NetApp volume endpoint"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = var.network_self_link
    }
  }

  depends_on = [google_service_networking_connection.default]
}

# DNS A record pointing to the NetApp volume IP
resource "google_dns_record_set" "netapp_a_record" {
  count        = var.enable_netapp_dns && local.is_multizone ? 1 : 0
  name         = "${var.netapp_dns_hostname}.${var.netapp_dns_zone_name}."
  type         = "A"
  ttl          = var.netapp_dns_record_ttl
  managed_zone = google_dns_managed_zone.netapp_private_zone[0].name

  rrdatas = [split(":", google_netapp_volume.netapp-nfs-volume.mount_options[0].export_full)[0]]
}
