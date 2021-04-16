# locals {
#   subnet_names_defaults = {
#     gke                     = "${var.prefix}-gke-subnet"
#     misc                    = "${var.prefix}-misc-subnet"
#     gke_pods_range_name     = "${var.prefix}-gke-pods"
#     gke_services_range_name = "${var.prefix}-gke-services"
#   }
#   subnet_names         = ( var.subnet_names == null 
#     ? local.subnet_names_defaults 
#     : var.subnet_names
#   )

#   gke_pod_range_index = index(module.vpc.subnets["gke"].secondary_ip_range.*.range_name, local.subnet_names["gke_pods_range_name"])
#   gke_pod_subnet_cidr = (var.subnet_names == null 
#     ? var.gke_pod_subnet_cidr 
#     : module.vpc.subnets[local.gke_pod_range_index].ip_cidr_range
#   )
#   gke_subnet_cidr = (var.subnet_names == null 
#     ? var.gke_subnet_cidr 
#     : module.vpc.subnets["gke"].ip_cidr_range
#   )

# }


data "google_compute_address" "nat_address" {
  count   = var.nat_address_name == null ? 0 : 1
  name    = var.nat_address_name
  project = var.project
  region  = local.region
}

module "nat_address" {
  count        = var.nat_address_name == null ? 1 : 0
  source       = "terraform-google-modules/address/google"
  version      = "2.1.1"
  project_id   = var.project
  region       = local.region
  address_type = "EXTERNAL"
  names = [
    "${var.prefix}-nat-address"
  ]
}

module "cloud_nat" {
  count        = var.nat_address_name == null ? 1 : 0
  source        = "terraform-google-modules/cloud-nat/google"
  version       = "1.4.0"
  project_id    = var.project
  name          = "${var.prefix}-cloud-nat"
  region        = local.region
  create_router = true
  router        = "${var.prefix}-router"
  network       = module.vpc.network_self_link
  nat_ips       = module.nat_address.0.self_links
}


module "vpc" {
  source                  = "./modules/network"
  vpc_name                = var.vpc_name
  project                 = var.project
  prefix                  = var.prefix
  region                  = local.region
  subnet_names            = local.subnet_names
  gke_subnet_cidr         = var.gke_subnet_cidr
  misc_subnet_cidr        = var.misc_subnet_cidr
  gke_pod_subnet_cidr     = var.gke_pod_subnet_cidr
  gke_service_subnet_cidr = var.gke_service_subnet_cidr
}


# All about how to use "private ip" to configure access from gke to cloud sql:
# https://cloud.google.com/sql/docs/postgres/private-ip

resource "google_compute_global_address" "private_ip_address" {
  name  = "${var.prefix}-private-ip-address"
  count = var.create_postgres ? 1 : 0

  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = "192.168.4.0"
  prefix_length = 22
  network       = module.vpc.network_self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.create_postgres ? 1 : 0

  network                 = module.vpc.network_name
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}

resource "google_compute_firewall" "nfs_vm_cluster_firewall" {
  name    = "${var.prefix}-nfs-server-cluster-firewall"
  count   = var.storage_type == "standard" ? 1 : 0
  network = module.vpc.network_name

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }

  target_tags = ["${var.prefix}-nfs-server"] # matches the tag on the nfs server

  # the node group vms are tagged with the cluster name
  source_tags = ["${var.prefix}-gke", "${var.prefix}-jump-server"]
  source_ranges = distinct(concat([local.gke_pod_subnet_cidr], [local.gke_subnet_cidr])) # allow the pods
}

resource "google_compute_firewall" "nfs_vm_firewall" {
  name    = "${var.prefix}-nfs-server-firewall"
  count   = (var.storage_type == "standard" && var.create_nfs_public_ip) ? 1 : 0
  network = module.vpc.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["${var.prefix}-nfs-server"] # matches the tag on the jump server

  source_ranges = local.vm_public_access_cidrs
}

resource "google_compute_firewall" "jump_vm_firewall" {
  name  = "${var.prefix}-jump-server-firewall"
  count = (var.create_jump_public_ip && var.create_jump_vm && length(local.vm_public_access_cidrs) != 0) ? 1 : 0

  network = module.vpc.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["${var.prefix}-jump-server"] # matches the tag on the jump server

  source_ranges = local.vm_public_access_cidrs
}
