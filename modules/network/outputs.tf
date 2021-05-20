output "network_name" {
  value = length(var.vpc_name) == 0 ? element(coalescelist(google_compute_network.vpc.*.name,[" "]),0) : var.vpc_name
}

output "network_self_link" {
  value = length(var.vpc_name) == 0 ? element(coalescelist(google_compute_network.vpc.*.self_link,[" "]),0) : data.google_compute_network.vpc.0.self_link
}

output subnets {
  value = {
    gke  : var.create_subnets ? google_compute_subnetwork.gke_subnet.0  : data.google_compute_subnetwork.gke_subnet.0
    misc : var.create_subnets ? google_compute_subnetwork.misc_subnet.0 : data.google_compute_subnetwork.misc_subnet.0
  }
}
