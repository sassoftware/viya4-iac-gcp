data "template_file" "nfs_cloudconfig" {
  # https://blog.woohoosvcs.com/2019/11/cloud-init-on-google-compute-engine/
  template = file("${path.module}/files/cloud-init/nfs/cloud-config")
  count    = var.storage_type == "standard" ? 1 : 0
  vars = {
    misc_subnet_cidr    = local.misc_subnet_cidr
    gke_subnet_cidr     = local.gke_subnet_cidr
    vm_admin            = var.nfs_vm_admin
  }
}

data "template_file" "jump_cloudconfig" {
  template = file("${path.module}/files/cloud-init/jump/cloud-config")
  count    = var.create_jump_vm ? 1 : 0
  vars = {
    rwx_filestore_endpoint  = ( var.storage_type == "none"
                                ? ""
                                : var.storage_type == "ha" ? google_filestore_instance.rwx.0.networks.0.ip_addresses.0 : module.nfs_server.0.private_ip
                              )
    rwx_filestore_path      = ( var.storage_type == "none"
                                ? ""
                                : var.storage_type == "ha" ? "/${google_filestore_instance.rwx.0.file_shares.0.name}" : "/export"
                              )
    vm_admin                = var.jump_vm_admin
    jump_rwx_filestore_path = var.jump_rwx_filestore_path
  }
  depends_on = [module.nfs_server, google_filestore_instance.rwx ]
}

module "nfs_server" {
  source           = "./modules/google_vm"
  project          = var.project
  count            = var.storage_type == "standard" ? 1 : 0
  create_public_ip = var.create_nfs_public_ip

  name             = "${var.prefix}-nfs-server"
  machine_type     = var.nfs_vm_type
  region           = local.region
  zone             = local.zone
  tags             = var.tags

  subnet           = local.subnet_names["misc"] // Name or self_link to subnet
  os_image         = "ubuntu-os-cloud/ubuntu-2004-lts"

  vm_admin         = var.nfs_vm_admin
  ssh_public_key   = local.ssh_public_key

  user_data        = length(data.template_file.nfs_cloudconfig) == 1 ? data.template_file.nfs_cloudconfig.0.rendered : null

  data_disk_count  = 4
  data_disk_size   = var.nfs_raid_disk_size

  depends_on       = [ module.vpc ]
}

module "jump_server" {
  source           = "./modules/google_vm"
  project          = var.project
  count            = var.create_jump_vm ? 1 : 0
  create_public_ip = var.create_jump_public_ip

  name             = "${var.prefix}-jump-server"
  machine_type     = var.jump_vm_type
  region           = local.region
  zone             = local.zone
  tags             = var.tags

  subnet           = local.subnet_names["misc"] // Name or self_link to subnet
  os_image         = "ubuntu-os-cloud/ubuntu-2004-lts"

  vm_admin         = var.jump_vm_admin
  ssh_public_key   = local.ssh_public_key

  user_data        = length(data.template_file.jump_cloudconfig) == 1 ? data.template_file.jump_cloudconfig.0.rendered : null

  depends_on       = [module.nfs_server]
}
