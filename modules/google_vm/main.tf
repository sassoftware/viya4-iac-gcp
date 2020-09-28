resource "google_compute_instance" "google_vm" {
  count        = var.create_vm ? 1 : 0
  name         = var.name
  machine_type = var.machine_type
  zone         = var.location
  ### TODO: check if it works with region
  labels = var.tags

  tags = [var.name] # to match the firewall rule

  boot_disk {
    initialize_params {
      image = var.os_image
    }
  }

  network_interface {
    subnetwork = var.subnet

    dynamic "access_config" {
      for_each = var.create_public_ip == true ? [1] : []
      content {}
    }
  }

  metadata = {
    ssh-keys       = "${var.vm_admin}:${file("${var.ssh_public_key}")}"
    user-data      = var.user_data_type == "cloud-init" ? var.user_data : null     # cloud-init for ubuntu
    startup-script = var.user_data_type == "startup-script" ? var.user_data : null # no cloud-init for centos
  }


  dynamic "attached_disk" {
    for_each = google_compute_disk.raid_disk
    content {
      source      = attached_disk.value.self_link
      device_name = attached_disk.value.name
    }
  }

  allow_stopping_for_update = true
  service_account {
    scopes = ["logging-write"]
  }
}


resource "google_compute_disk" "raid_disk" {
  count  = var.create_vm ? var.data_disk_count : 0
  zone   = var.location # TODO: test with region
  name   = "${var.name}-disk-${count.index}"
  labels = var.tags
  type   = var.data_disk_type
  size   = var.data_disk_size
}