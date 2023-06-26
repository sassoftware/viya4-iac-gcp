# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

data "google_compute_network" "vpc" {
  count = length(var.vpc_name) == 0 ? 0 : 1
  name  = var.vpc_name
}
resource "google_compute_network" "vpc" {
  count                   = length(var.vpc_name) < 1 ? 1 : 0
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
}

data "google_compute_subnetwork" "gke_subnet" {
  count  = var.create_subnets ? 0 : 1
  name   = var.subnet_names["gke"]
  region = var.region
}
resource "google_compute_subnetwork" "gke_subnet" {
  count                    = var.create_subnets ? 1 : 0
  name                     = var.subnet_names["gke"]
  ip_cidr_range            = var.gke_subnet_cidr
  region                   = var.region
  network                  = length(var.vpc_name) == 0 ? google_compute_network.vpc[0].id : data.google_compute_network.vpc[0].id
  private_ip_google_access = true
  secondary_ip_range {
    range_name    = var.subnet_names["gke_pods_range_name"]
    ip_cidr_range = var.gke_pod_subnet_cidr // /17
  }
  secondary_ip_range {
    range_name    = var.subnet_names["gke_services_range_name"]
    ip_cidr_range = var.gke_service_subnet_cidr // /22
  }
}

data "google_compute_subnetwork" "misc_subnet" {
  count  = var.create_subnets ? 0 : 1
  name   = var.subnet_names["misc"]
  region = var.region
}
resource "google_compute_subnetwork" "misc_subnet" {
  count                    = var.create_subnets ? 1 : 0
  name                     = var.subnet_names["misc"]
  ip_cidr_range            = var.misc_subnet_cidr
  region                   = var.region
  network                  = length(var.vpc_name) == 0 ? google_compute_network.vpc[0].id : data.google_compute_network.vpc[0].id
  private_ip_google_access = false
}
