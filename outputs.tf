output "cluster_name" {
  description = "GKE Cluster name"
  value       = module.gke_cluster.cluster_name
}

output "public_endpoint" {
  description = "GKE Cluster public IP"
  value       = module.gke_cluster.public_endpoint
}

output "kube_config" {
  value = module.gke_cluster.kubeconfig_raw
}

output "postgres_server_private_ip" {
  description = "Private IP of the PostgreSQL server. Use this value to set DATABASE_HOST in your Viya deployment."
  value       = module.postgresql.postgres_server_private_ip
}

output "rwx_filestore_endpoint" {
  description = "Shared Storage private IP"
  value       = coalesce(module.rwx_filestore.ip, module.nfs_server.private_ip)
}

output "rwx_filestore_path" {
  description = "Shared Storage mount path"
  value       = var.storage_type == "standard" ? "/export" : "/${module.rwx_filestore.mount_path}"
}

output "nat_ip" {
  description = "Public IP of NAT for private network."
  value       = module.network.nat_ip
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

# bastion server
output "jump_private_ip" {
  value = module.jump_server.private_ip
}

output "jump_public_ip" {
  value = module.jump_server.public_ip
}

output jump_admin_username {
  value = module.jump_server.admin_username
}


# NFS server
output "nfs_private_ip" {
  value = var.storage_type == "standard" ? module.nfs_server.private_ip : null
}

output "nfs_public_ip" {
  value = var.storage_type == "standard" ? module.nfs_server.public_ip : null
}

output "nfs_admin_username" {
  value = var.storage_type == "standard" ? module.nfs_server.admin_username : null
}
