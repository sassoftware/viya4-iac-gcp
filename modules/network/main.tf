data "google_compute_network" "vpc" {
  count = var.vpc_name == null ? 0 : 1
  name  = var.vpc_name
}
resource "google_compute_network" "vpc" {
  count                   = var.vpc_name == null ? 1 : 0
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
}

data "google_compute_subnetwork" "gke_subnet" {
  count = var.subnet_names == null ? 0 : 1
  name          = var.subnet_names["gke"]
  region        = var.region
}
resource "google_compute_subnetwork" "gke_subnet" {
  count = var.subnet_names == null ? 1 : 0
  name          = var.subnet_names["gke"]
  ip_cidr_range = var.gke_subnet_cidr
  region        = var.region
  network       = var.vpc_name == null ? google_compute_network.vpc.0.id : data.google_compute_network.vpc.0.id
  private_ip_google_access  = true
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
  count = var.subnet_names == null ? 0 : 1
  name          = var.subnet_names["misc"]
  region        = var.region
}
resource "google_compute_subnetwork" "misc_subnet" {
  count = var.subnet_names == null ? 1 : 0
  name          = var.subnet_names["misc"]
  ip_cidr_range = var.misc_subnet_cidr
  region        = var.region
  network       = var.vpc_name == null ? google_compute_network.vpc.0.id : data.google_compute_network.vpc.0.id
  private_ip_google_access  = false
}


# resource "google_compute_firewall" "nfs_vm_cluster_firewall" {
#   name    = "${var.prefix}-nfs-server-cluster-firewall"
#   count   = var.storage_type == "standard" ? 1 : 0
#   network = var.vpc_name

#   allow {
#     protocol = "tcp"
#   }
#   allow {
#     protocol = "udp"
#   }

#   target_tags = ["${var.prefix}-nfs-server"] # matches the tag on the nfs server

#   # the node group vms are tagged with the cluster name
#   source_tags = ["${var.prefix}-gke", "${var.prefix}-jump-server"]
#   source_ranges = distinct(concat([local.gke_pod_subnet_cidr], [local.gke_subnet_cidr])) # allow the pods
# }


