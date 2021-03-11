data "template_file" "nfs_cloudconfig" {
  # https://blog.woohoosvcs.com/2019/11/cloud-init-on-google-compute-engine/
  template = file("${path.module}/cloud-init/nfs/cloud-config")
  count    = var.storage_type == "standard" ? 1 : 0
  vars = {
    misc_subnet_cidr  = var.misc_subnet_cidr
    gke_pod_subnet_cidr = var.gke_pod_subnet_cidr
    vm_admin = var.nfs_vm_admin
  }
}

data "template_file" "jump_cloudconfig" {
  template = file("${path.module}/cloud-init/jump/cloud-config")
  count    = var.create_jump_vm ? 1 : 0
  vars = {
    nfs_rwx_filestore_endpoint  = (var.storage_type == "ha" ? element(coalescelist(google_filestore_instance.rwx.*.networks.0.ip_addresses.0,[""]),0) : module.nfs_server.private_ip )
    nfs_rwx_filestore_path      = (var.storage_type == "ha" ? "/${element(coalescelist(google_filestore_instance.rwx.*.file_shares.0.name,[""]),0)}" : "/export")
    vm_admin                    = var.jump_vm_admin
    jump_rwx_filestore_path     = var.jump_rwx_filestore_path
  }
  depends_on = [module.nfs_server, google_filestore_instance.rwx ]
}

# TODO - Again tf.reg module if needed
module "nfs_server" {
  source           = "./modules/google_vm"
  create_vm        = var.storage_type == "standard" ? true : false
  create_public_ip = var.create_nfs_public_ip

  name         = "${var.prefix}-nfs-server"
  machine_type = "n1-standard-1"
  location     = local.zone
  tags         = var.tags

  subnet   = "${var.prefix}-misc-subnet" // Name or self_link to subnet
  os_image = "ubuntu-os-cloud/ubuntu-1804-lts"

  vm_admin       = var.nfs_vm_admin
  ssh_public_key = local.ssh_public_key

  user_data      = length(data.template_file.nfs_cloudconfig) == 1 ? data.template_file.nfs_cloudconfig.0.rendered : null
  user_data_type = "cloud-init"

  data_disk_count = 4
  data_disk_size  = var.nfs_raid_disk_size

  depends_on = [ module.vpc ]
}

# TODO - Again tf.reg module if needed
module "jump_server" {

  source           = "./modules/google_vm"
  create_vm        = var.create_jump_vm
  create_public_ip = var.create_jump_public_ip

  name         = "${var.prefix}-jump-server"
  machine_type = "n1-standard-1"
  location     = local.zone
  tags         = var.tags

  subnet   = "${var.prefix}-misc-subnet" // Name or self_link to subnet
  os_image = "ubuntu-os-cloud/ubuntu-1804-lts"

  vm_admin       = var.jump_vm_admin
  ssh_public_key = local.ssh_public_key

  user_data      = length(data.template_file.jump_cloudconfig) == 1 ? data.template_file.jump_cloudconfig.0.rendered : null
  user_data_type = "cloud-init"

  depends_on = [module.nfs_server]
}