# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

locals {
  rwx_filestore_endpoint = (var.storage_type == "none"
    ? ""
    : var.storage_type == "ha" ? google_filestore_instance.rwx.0.networks.0.ip_addresses.0 : module.nfs_server.0.private_ip
  )
  rwx_filestore_path = (var.storage_type == "none"
    ? ""
    : var.storage_type == "ha" ? "/${google_filestore_instance.rwx.0.file_shares.0.name}" : "/export"
  )
}

module "nfs_server" {
  source           = "./modules/google_vm"
  project          = var.project
  count            = var.storage_type == "standard" ? 1 : 0
  create_public_ip = var.create_nfs_public_ip

  name         = "${var.prefix}-nfs-server"
  machine_type = var.nfs_vm_type
  region       = local.region
  zone         = local.zone
  tags         = var.tags

  subnet   = local.subnet_names["misc"] // Name or self_link to subnet
  os_image = "ubuntu-os-cloud/ubuntu-2004-lts"

  vm_admin       = var.nfs_vm_admin
  ssh_public_key = local.ssh_public_key

  user_data = var.storage_type == "standard" ? templatefile("${path.module}/files/cloud-init/nfs/cloud-config", {
    misc_subnet_cidr = local.misc_subnet_cidr
    gke_subnet_cidr  = local.gke_subnet_cidr
    vm_admin         = var.nfs_vm_admin
    }
  ) : null

  data_disk_count = 4
  data_disk_size  = var.nfs_raid_disk_size

  depends_on = [module.vpc]
}

module "jump_server" {
  source           = "./modules/google_vm"
  project          = var.project
  count            = var.create_jump_vm ? 1 : 0
  create_public_ip = var.create_jump_public_ip

  name         = "${var.prefix}-jump-server"
  machine_type = var.jump_vm_type
  region       = local.region
  zone         = local.zone
  tags         = var.tags

  subnet   = local.subnet_names["misc"] // Name or self_link to subnet
  os_image = "ubuntu-os-cloud/ubuntu-2004-lts"

  vm_admin       = var.jump_vm_admin
  ssh_public_key = local.ssh_public_key

  user_data = templatefile("${path.module}/files/cloud-init/jump/cloud-config", {
    mounts = (var.storage_type == "none"
      ? "[]"
      : jsonencode(
        ["${local.rwx_filestore_endpoint}:${local.rwx_filestore_path}",
          var.jump_rwx_filestore_path,
          "nfs",
          "_netdev,auto,x-systemd.automount,x-systemd.mount-timeout=10,timeo=14,x-systemd.idle-timeout=1min,relatime,hard,rsize=65536,wsize=65536,vers=3,tcp,namlen=255,retrans=2,sec=sys,local_lock=none",
          "0",
          "0"
      ])
    )
    rwx_filestore_endpoint  = local.rwx_filestore_endpoint
    rwx_filestore_path      = local.rwx_filestore_path
    vm_admin                = var.jump_vm_admin
    jump_rwx_filestore_path = var.jump_rwx_filestore_path
    }
  )

  depends_on = [module.nfs_server, google_filestore_instance.rwx]
}
