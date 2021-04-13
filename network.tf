data "google_compute_subnetwork" "subnetwork" {
  name       = "${var.prefix}-gke-subnet"
  project    = var.project
  region     = local.region
  depends_on = [module.vpc]
}

module "nat_address" {
  source       = "terraform-google-modules/address/google"
  version      = "2.1.1"
  project_id   = var.project
  region       = local.region
  address_type = "EXTERNAL"
  names = [
    "${var.prefix}-nat-address"
  ]
}

module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "3.1.2"
  project_id   = var.project
  network_name = "${var.prefix}-vpc"

  subnets = [
    {
      subnet_name           = "${var.prefix}-gke-subnet"
      subnet_ip             = var.gke_subnet_cidr // /23
      subnet_region         = local.region
      subnet_private_access = true
    },
    {
      subnet_name           = "${var.prefix}-misc-subnet"
      subnet_ip             = var.misc_subnet_cidr // /24
      subnet_region         = local.region
      subnet_private_access = false
    },
  ]

  secondary_ranges = {
    "${var.prefix}-gke-subnet" = [
      {
        range_name    = "${var.prefix}-gke-pods"
        ip_cidr_range = var.gke_pod_subnet_cidr // /17
      },
      {
        range_name    = "${var.prefix}-gke-services"
        ip_cidr_range = var.gke_service_subnet_cidr // /22
      }
    ]
  }
}

module "cloud_nat" {
  source        = "terraform-google-modules/cloud-nat/google"
  version       = "1.4.0"
  project_id    = var.project
  name          = "${var.prefix}-cloud-nat"
  region        = local.region
  create_router = true
  router        = "${var.prefix}-router"
  network       = module.vpc.network_self_link
  nat_ips       = module.nat_address.self_links
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
  source_tags   = ["${var.prefix}-gke", "${var.prefix}-jump-server"]
  source_ranges = distinct(concat([var.gke_pod_subnet_cidr], [var.gke_subnet_cidr])) # allow the pods
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
