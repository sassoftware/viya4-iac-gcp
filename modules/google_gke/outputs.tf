#cluster_ipv4_cidr
output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "public_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "pod_cidr" {
  value = google_container_cluster.primary.cluster_ipv4_cidr
}

output "cluster_ca_certificate" {
  value = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

output "cluster_user_name" {
  value = google_container_cluster.primary.master_auth[0].username
}
output "cluster_user_password" {
  value = google_container_cluster.primary.master_auth[0].password
}
output "kubeconfig_raw" {
  value = data.template_file.kubeconfig.rendered
}

output "location" {
  value = google_container_cluster.primary.location
}
