locals {
  subnet_names_defaults = {
    gke                     = "${var.prefix}-gke-subnet"
    misc                    = "${var.prefix}-misc-subnet"
    gke_pods_range_name     = "${var.prefix}-gke-pods"
    gke_services_range_name = "${var.prefix}-gke-services"
  }
  subnet_names = var.subnet_names == null ? local.subnet_names_defaults : var.subnet_names
}

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
  name          = local.subnet_names["gke"]
  region        = var.region
}
resource "google_compute_subnetwork" "gke_subnet" {
  count = var.subnet_names == null ? 1 : 0
  name          = local.subnet_names["gke"]
  ip_cidr_range = var.gke_subnet_cidr
  region        = var.region
  network       = var.vpc_name == null ? google_compute_network.vpc.0.id : data.google_compute_network.vpc.0.id
  private_ip_google_access  = true
  secondary_ip_range {
    range_name    = local.subnet_names["gke_pods_range_name"]
    ip_cidr_range = var.gke_pod_subnet_cidr // /17
  }
  secondary_ip_range {
    range_name    = local.subnet_names["gke_services_range_name"]
    ip_cidr_range = var.gke_service_subnet_cidr // /22
  }
}

data "google_compute_subnetwork" "misc_subnet" {
  count = var.subnet_names == null ? 0 : 1
  name          = local.subnet_names["misc"]
  region        = var.region
}
resource "google_compute_subnetwork" "misc_subnet" {
  count = var.subnet_names == null ? 1 : 0
  name          = local.subnet_names["misc"]
  ip_cidr_range = var.misc_subnet_cidr
  region        = var.region
  network       = var.vpc_name == null ? google_compute_network.vpc.0.id : data.google_compute_network.vpc.0.id
  private_ip_google_access  = false
}



# module "nat_address" {
#   source       = "terraform-google-modules/address/google"
#   version      = "2.1.1"
#   project_id   = var.project
#   region       = local.region
#   address_type = "EXTERNAL"
#   names = [
#     "${var.prefix}-nat-address"
#   ]
# }



# module "cloud_nat" {
#   source        = "terraform-google-modules/cloud-nat/google"
#   version       = "1.4.0"
#   project_id    = var.project
#   name          = "${var.prefix}-cloud-nat"
#   region        = local.region
#   create_router = true
#   router        = "${var.prefix}-router"
#   network       = module.vpc.network_self_link
#   nat_ips       = module.nat_address.self_links
# }


# resource "google_compute_firewall" "nfs_vm_cluster_firewall" {
#   name    = "${var.prefix}-nfs-server-cluster-firewall"
#   count   = var.storage_type == "standard" ? 1 : 0
#   network = module.vpc.network_name

#   allow {
#     protocol = "tcp"
#   }
#   allow {
#     protocol = "udp"
#   }

#   target_tags = ["${var.prefix}-nfs-server"] # matches the tag on the nfs server

#   # the node group vms are tagged with the cluster name
#   source_tags = ["${var.prefix}-gke", "${var.prefix}-jump-server"]
#   source_ranges = distinct(concat([var.gke_pod_subnet_cidr], [var.gke_subnet_cidr])) # allow the pods
# }

# resource "google_compute_firewall" "nfs_vm_firewall" {
#   name    = "${var.prefix}-nfs-server-firewall"
#   count   = (var.storage_type == "standard" && var.create_nfs_public_ip) ? 1 : 0
#   network = module.vpc.network_name

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

#   target_tags = ["${var.prefix}-nfs-server"] # matches the tag on the jump server

#   source_ranges = local.vm_public_access_cidrs
# }

# resource "google_compute_firewall" "jump_vm_firewall" {
#   name  = "${var.prefix}-jump-server-firewall"
#   count = (var.create_jump_public_ip && var.create_jump_vm && length(local.vm_public_access_cidrs) != 0) ? 1 : 0

#   network = module.vpc.network_name

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

#   target_tags = ["${var.prefix}-jump-server"] # matches the tag on the jump server

#   source_ranges = local.vm_public_access_cidrs
# }
