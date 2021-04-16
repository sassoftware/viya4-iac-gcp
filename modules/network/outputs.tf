output "network_name" {
  value = var.vpc_name == null ? google_compute_network.vpc.0.name : var.vpc_name
}

output "network_self_link" {
  value = var.vpc_name == null ? google_compute_network.vpc.0.self_link : data.google_compute_network.vpc.0.self_link
}

output subnets {
  value = {
    gke : var.subnet_names == null ? google_compute_subnetwork.gke_subnet.0 : data.google_compute_subnetwork.gke_subnet.0
    misc: var.subnet_names == null ? google_compute_subnetwork.misc_subnet.0 : data.google_compute_subnetwork.misc_subnet.0
  }
}
