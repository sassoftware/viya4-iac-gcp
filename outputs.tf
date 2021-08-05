output "cluster_name" {
  description = "GKE Cluster name"
  value       = module.gke.name
}

output "cluster_endpoint" {
  description = "GKE Cluster public IP"
  value       = module.gke.endpoint
  sensitive   = true
}

output "kube_config" {
  value = module.kubeconfig.kube_config
  sensitive = true
}

#postgres
output "postgres_servers" {
  value = length(module.postgresql) != 0 ? local.postgres_outputs : null
  sensitive = true
}

output "sql_proxy_sa_email" {
  value = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? module.sql_proxy_sa.0.service_account.email : null : null
}

output "rwx_filestore_endpoint" {
  description = "Shared Storage private IP"
  value       = var.storage_type == "ha" ? element(coalescelist(google_filestore_instance.rwx.*.networks.0.ip_addresses.0,[""]),0) : module.nfs_server.0.private_ip
}

output "rwx_filestore_path" {
  description = "Shared Storage mount path"
  value       = var.storage_type == "ha" ? "/${element(coalescelist(google_filestore_instance.rwx.*.file_shares.0.name,[""]),0)}" : "/export"
}

output "nat_ip" {
  description = "Public IP of NAT for private network."
  value       = length(var.nat_address_name) == 0 ? (length(module.nat_address.0.addresses) > 0 ? element(module.nat_address.0.addresses, 0) : null) : data.google_compute_address.nat_address.0.address
}

output "prefix" {
  value = var.prefix
}

output "location" {
  value = var.location
}

output "provider_account" {
  value = data.google_client_config.current.project
}

output "provider" {
  value = "gcp"
}

# # bastion server
output "jump_private_ip" {
  value = var.create_jump_vm ? module.jump_server.0.private_ip : null
}

output "jump_public_ip" {
  value = var.create_jump_vm ? module.jump_server.0.public_ip : null
}

output "jump_rwx_filestore_path" {
  value = var.create_jump_vm ? var.jump_rwx_filestore_path : null
}

output "jump_admin_username" {
  value = var.create_jump_vm ? module.jump_server.0.admin_username : null
}

# NFS server
output "nfs_private_ip" {
  value = var.storage_type == "ha" ? null : module.nfs_server.0.private_ip
}

output "nfs_public_ip" {
  value = var.storage_type == "ha" ? null : module.nfs_server.0.public_ip
}

output "nfs_admin_username" {
  value = var.storage_type == "ha" ? null : module.nfs_server.0.admin_username
}

# Container regsitry
output "cr_endpoint" {
  value = var.create_container_registry ? "https://gcr.io/${var.project}" : null
}

output "cluster_node_pool_mode" {
  value = var.cluster_node_pool_mode
}
