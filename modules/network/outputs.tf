
output "id" {
  value = google_compute_network.vpc.id
}

output "name" {
  value = google_compute_network.vpc.name
}

output "subnet" {
  value = google_compute_subnetwork.subnet.self_link
}

output "nat_ip" {
  value = (length(google_compute_address.address) > 0
    ? google_compute_address.address[0].address
  : null)
}
