# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

module "address" {
  source       = "terraform-google-modules/address/google"
  version      = "3.1.2"
  project_id   = var.project
  region       = var.region
  address_type = "EXTERNAL"
  names        = var.create_public_ip ? ["${var.name}-address"] : []
}

resource "google_compute_instance" "google_vm" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone
  labels       = var.tags

  tags = [var.name] # to match the firewall rule

  boot_disk {
    initialize_params {
      image = var.os_image
    }
  }

  network_interface {
    subnetwork = var.subnet

    dynamic "access_config" {
      for_each = module.address.addresses
      content {
        nat_ip = access_config.value
      }
    }
  }

  metadata = {
    ssh-keys  = "${var.vm_admin}:${var.ssh_public_key}"
    user-data = var.user_data // cloud-init
  }

  dynamic "attached_disk" {
    for_each = google_compute_disk.raid_disk
    content {
      source      = attached_disk.value.self_link
      device_name = attached_disk.value.name
    }
  }

  allow_stopping_for_update = true
}

resource "google_compute_disk" "raid_disk" {
  count  = var.data_disk_count
  zone   = var.zone
  name   = "${var.name}-disk-${count.index}"
  labels = var.tags
  type   = var.data_disk_type
  size   = var.data_disk_size
}
