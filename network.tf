# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

data "google_compute_address" "nat_address" {
  count   = length(var.nat_address_name) == 0 ? 0 : 1
  name    = var.nat_address_name
  project = var.project
  region  = local.region
}

module "nat_address" {
  count        = length(var.nat_address_name) == 0 ? 1 : 0
  source       = "terraform-google-modules/address/google"
  version      = "3.1.2"
  project_id   = var.project
  region       = local.region
  address_type = "EXTERNAL"
  names = [
    "${var.prefix}-nat-address"
  ]
}

module "cloud_nat" {
  count         = length(var.nat_address_name) == 0 ? 1 : 0
  source        = "terraform-google-modules/cloud-nat/google"
  version       = "3.0.0"
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
  vpc_name                = trimspace(var.vpc_name)
  project                 = var.project
  prefix                  = var.prefix
  region                  = local.region
  subnet_names            = local.subnet_names
  create_subnets          = length(var.subnet_names) == 0 ? true : false
  gke_subnet_cidr         = var.gke_subnet_cidr
  misc_subnet_cidr        = var.misc_subnet_cidr
  gke_pod_subnet_cidr     = var.gke_pod_subnet_cidr
  gke_service_subnet_cidr = var.gke_service_subnet_cidr
}

# All about how to use "private ip" to configure access from gke to cloud sql:
# https://cloud.google.com/sql/docs/postgres/private-ip

resource "google_compute_global_address" "private_ip_address" {
  name  = "${var.prefix}-private-ip-address"
  count = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? 1 : 0 : 0

  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = split("/", var.database_subnet_cidr)[0]
  prefix_length = split("/", var.database_subnet_cidr)[1]
  network       = module.vpc.network_self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? 1 : 0 : 0

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
  source_tags   = ["${var.prefix}-gke", "${var.prefix}-jump-server"]
  source_ranges = distinct(concat([local.gke_pod_subnet_cidr], [local.gke_subnet_cidr])) # allow the pods
}

resource "google_compute_firewall" "nfs_vm_firewall" {
  name    = "${var.prefix}-nfs-server-firewall"
  count   = (var.storage_type == "standard" && var.create_nfs_public_ip && length(local.vm_public_access_cidrs) != 0) ? 1 : 0
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
