terraform {
  required_version = ">= 0.13"

  required_providers {
    google      = ">= 3.42.0"
    google-beta = ">= 3.42.0"
  }
}

provider "google" {
  credentials = file(var.service_account_keyfile)
  project     = var.project
}

provider "google-beta" {
  credentials = file(var.service_account_keyfile)
  project     = var.project
}

resource "local_file" "kubeconfig" {
  content  = module.gke_cluster.kubeconfig_raw
  filename = "${var.prefix}-gcp-kubeconfig.conf"
}

data "google_client_config" "current" {}

data "google_compute_zones" "available" {
  region = local.region
}

locals {

  # get the region from "location", or else from the local config
  region = var.location != "" ? regex("^[a-z0-9]*-[a-z0-9]*", var.location) : data.google_client_config.current.region

  # get the zone from "location", or else from the local config. If none is set, default to the first zone in the region
  is_region  = var.location != "" ? var.location == regex("^[a-z0-9]*-[a-z0-9]*", var.location) : false
  first_zone = length(data.google_compute_zones.available.names) > 0 ? data.google_compute_zones.available.names[0] : ""
  zone = (var.location != ""
    ? (local.is_region ? local.first_zone : var.location)
    : (data.google_client_config.current.zone == "" ? local.first_zone : data.google_client_config.current.zone)
  )
  location = var.location != "" ? var.location : local.zone

  cluster_name = "${var.prefix}-gke"

  pod_cidr_block = "10.2.0.0/16"
  vm_cidr_block  = "10.5.0.0/16"

  create_jump_vm_default = var.storage_type == "standard" ? true : false
  create_jump_vm         = var.create_jump_vm != null ? var.create_jump_vm : local.create_jump_vm_default

  default_public_access_cidrs          = var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs
  vm_public_access_cidrs               = var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs
  postgres_public_access_cidrs         = var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs

}

module "network" {
  source            = "./modules/network"
  name              = "${var.prefix}-vpc"
  region            = local.region
  project           = data.google_client_config.current.project
  subnet_cidr_block = local.vm_cidr_block
}

data "template_file" "nfs_cloudconfig" {
  # https://blog.woohoosvcs.com/2019/11/cloud-init-on-google-compute-engine/
  template = file("${path.module}/files/nfs-cloud-config")
  count    = var.storage_type == "standard" ? 1 : 0
  vars = {
    vm_cidr_block = local.vm_cidr_block
  }
}

module "nfs_server" {
  source           = "./modules/google_vm"
  create_vm        = var.storage_type == "standard" ? true : false
  create_public_ip = var.create_nfs_public_ip

  name         = "${var.prefix}-nfs-server"
  machine_type = "n1-standard-1"
  location     = var.location
  tags         = var.tags

  subnet   = module.network.subnet
  os_image = "ubuntu-os-cloud/ubuntu-1804-lts"

  vm_admin       = var.nfs_vm_admin
  ssh_public_key = var.ssh_public_key

  user_data      = length(data.template_file.nfs_cloudconfig) == 1 ? "${data.template_file.nfs_cloudconfig.0.rendered}" : null
  user_data_type = "cloud-init"

  data_disk_count = 4
  data_disk_size  = var.nfs_raid_disk_size

}

data "template_file" "jump_bootstrap" {

  template = file("${path.module}/files/jump-nfs-mount.sh")
  count    = local.create_jump_vm ? 1 : 0

  vars = {
    rwx_filestore_endpoint = (var.storage_type == "standard"
      ? module.nfs_server.private_ip
    : module.rwx_filestore.ip)
    rwx_filestore_path = (var.storage_type == "standard"
      ? "/export"
    : "/${module.rwx_filestore.mount_path}")
  }
  depends_on = [module.nfs_server, module.rwx_filestore]

}

module "jump_server" {

  source           = "./modules/google_vm"
  create_vm        = local.create_jump_vm
  create_public_ip = var.create_jump_public_ip

  name         = "${var.prefix}-jump-server"
  machine_type = "n1-standard-1"
  location     = var.location
  tags         = var.tags

  subnet   = module.network.subnet
  os_image = "centos-cloud/centos-7"

  vm_admin       = var.jump_vm_admin
  ssh_public_key = var.ssh_public_key

  user_data      = length(data.template_file.jump_bootstrap) == 1 ? "${data.template_file.jump_bootstrap.0.rendered}" : null
  user_data_type = "startup-script"

  depends_on = [module.nfs_server]
}

# kubernetes cluster
module "gke_cluster" {
  source = "./modules/google_gke"

  name               = local.cluster_name
  location           = local.location
  kubernetes_version = var.kubernetes_version
  kubernetes_channel = var.kubernetes_channel
  labels             = var.tags
  network            = module.network.id
  subnet             = module.network.subnet
  endpoint_access    = local.cluster_endpoint_public_access_cidrs
  pod_cidr_block     = local.pod_cidr_block

  depends_on = [module.jump_server] # workaround to avoid jump server subnet error
}

module "rwx_filestore" {
  source           = "./modules/filestore"
  create_filestore = var.storage_type == "ha" ? true : false

  name = "${var.prefix}-rwx-filestore"
  zone = local.zone

  labels  = var.tags
  network = module.network.name
}

# postgres 
module "postgresql" {
  source          = "./modules/postgresql"
  create_postgres = var.create_postgres

  name                = "${var.prefix}-pgsql"
  location            = local.location
  labels              = var.tags
  network             = module.network.id
  public_access_cidrs = local.postgres_public_access_cidrs

  machine_type   = var.postgres_machine_type
  disk_size_gb   = var.postgres_storage_gb
  server_version = var.postgres_server_version

  administrator_login     = var.postgres_administrator_login
  administrator_password  = var.postgres_administrator_password
  ssl_enforcement_enabled = var.postgres_ssl_enforcement_enabled

}

# nodepools
module "default_node_pool" {
  source = "./modules/gke_node_pool"

  node_pool_name     = "default"
  gke_cluster        = module.gke_cluster.cluster_name
  node_pool_location = module.gke_cluster.location

  machine_type       = var.default_nodepool_vm_type
  os_disk_size       = var.default_nodepool_os_disk_size
  local_ssd_count    = var.default_nodepool_local_ssd_count
  initial_node_count = var.default_nodepool_initial_node_count
  max_nodes          = var.default_nodepool_max_nodes
  min_nodes          = var.default_nodepool_min_nodes
  node_taints        = var.default_nodepool_taints
  node_labels        = merge(var.tags, var.default_nodepool_labels)
}

module "node_pools" {
  source = "./modules/gke_node_pool"

  for_each = var.node_pools

  node_pool_name     = each.key
  gke_cluster        = module.gke_cluster.cluster_name
  node_pool_location = module.gke_cluster.location

  machine_type       = each.value.vm_type
  os_disk_size       = each.value.os_disk_size
  local_ssd_count    = each.value.local_ssd_count
  initial_node_count = each.value.min_nodes
  min_nodes          = each.value.min_nodes
  max_nodes          = each.value.max_nodes
  node_taints        = each.value.node_taints
  node_labels        = merge(var.tags, each.value.node_labels)
}


resource "google_compute_firewall" "nfs_vm_firewall" {
  name    = "${var.prefix}-nfs-server-firewall"
  count   = var.storage_type == "standard" ? 1 : 0
  network = module.network.id

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }

  target_tags = ["${var.prefix}-nfs-server"] # matches the tag on the nfs server

  # the node group vms are tagged with the cluster name
  source_tags = [module.gke_cluster.cluster_name,
  "${var.prefix}-jump-server"]
  source_ranges = distinct(concat([local.pod_cidr_block], var.create_nfs_public_ip ? local.vm_public_access_cidrs : [])) # allow the pods
}

resource "google_compute_firewall" "jump_vm_firewall" {
  name  = "${var.prefix}-jump-server-firewall"
  count = (var.create_jump_public_ip && local.create_jump_vm && length(local.vm_public_access_cidrs) != 0) ? 1 : 0

  network = module.network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["${var.prefix}-jump-server"] # matches the tag on the jump server

  source_ranges = local.vm_public_access_cidrs
}
