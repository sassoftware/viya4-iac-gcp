output "cluster_name" {
  description = "GKE Cluster name"
  value       = module.gke_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "GKE Cluster public IP"
  value       = module.gke_cluster.public_endpoint
}

output "kube_config" {
  value = module.gke_cluster.kubeconfig_raw
}

output "postgres_fqdn" {
  description = "Private IP of the PostgreSQL server. Use this value to set DATABASE_HOST in your Viya deployment."
  value       = module.postgresql.postgres_server_private_ip
}

output "postgres_server_public_ip" {
  description = "Public IP of the PostgreSQL server. Use this value to connect database clients."
  value       = length(local.postgres_public_access_cidrs) > 0 ? module.postgresql.postgres_server_public_ip : null
}

output "postgres_server_name" {
  value = var.create_postgres ? element(coalescelist(module.postgresql.*.postgres_server_name, [" "]), 0) : null
}
output "postgres_admin" {
  value = var.create_postgres ? element(coalescelist(module.postgresql.*.postgres_admin, [" "]), 0) : null
}
output "postgres_password" {
  value = var.create_postgres ? element(coalescelist(module.postgresql.*.postgres_password, [" "]), 0) : null
}
output "postgres_server_id" {
  value = var.create_postgres ? element(coalescelist(module.postgresql.*.postgres_server_id, [" "]), 0) : null
}
output "postgres_server_port" {
  value = var.create_postgres ? element(coalescelist(module.postgresql.*.postgres_server_port, [" "]), 0) : null
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



output "ssh_private_key" {
  value = var.ssh_public_key == "" ? element(coalescelist(data.tls_public_key.public_key.*.private_key_pem, [""]), 0) : null
}
output "ssh_public_key" {
  value = var.ssh_public_key == "" ? element(coalescelist(data.tls_public_key.public_key.*.public_key_pem, [""]), 0) : null
}


# bastion server
output "jump_private_ip" {
  value = module.jump_server.private_ip
}

output "jump_public_ip" {
  value = module.jump_server.public_ip
}

output "jump_admin_username" {
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
