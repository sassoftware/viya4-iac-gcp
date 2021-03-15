output "cluster_name" {
  description = "GKE Cluster name"
  value       = module.gke.name
}

output "cluster_endpoint" {
  description = "GKE Cluster public IP"
  value       = module.gke.endpoint
}

output "kube_config" {
  value = module.kubeconfig.kube_config
}

output "postgresql" {
  value = module.postgresql
}

output "postgres_fqdn" {
  description = "Private IP of the PostgreSQL server. Use this value to set DATABASE_HOST in your Viya deployment."
  value       = var.create_postgres ? module.postgresql.0.private_ip_address : null
}

output "postgres_server_public_ip" {
  description = "Public IP of the PostgreSQL server. Use this value to connect database clients."
  value       = (var.create_postgres && (length(local.postgres_public_access_cidrs) > 0)) ? module.postgresql.public_ip_address : null
}

# output "postgres_server_name" {
#   value = var.create_postgres ? element(coalescelist(module.postgresql.*.postgres_server_name, [" "]), 0) : null
# }
# output "postgres_admin" {
#   value = var.create_postgres ? element(coalescelist(module.postgresql.*.postgres_admin, [" "]), 0) : null
# }
# output "postgres_password" {
#   value = var.create_postgres ? element(coalescelist(module.postgresql.*.postgres_password, [" "]), 0) : null
# }
# output "postgres_server_id" {
#   value = var.create_postgres ? element(coalescelist(module.postgresql.*.postgres_server_id, [" "]), 0) : null
# }
# output "postgres_server_port" {
#   value = var.create_postgres ? element(coalescelist(module.postgresql.*.postgres_server_port, [" "]), 0) : null
# }


# output "rwx_filestore_endpoint" {
#   description = "Shared Storage private IP"
#   value       = var.storage_type == "ha" ? element(coalescelist(module.address.addresses, [""]), 0) : module.nfs_server.private_ip
# }

output "rwx_filestore_instance" {
  value = google_filestore_instance.rwx
}

# output "rwx_filestore_path" {
#   description = "Shared Storage mount path"
#   value       = coalesce("/${element(coalescelist(google_filestore_instance.rwx.*.file_shares.0.name,[""]),0)}", "/export")
# }

# output "nat_ip" {
#   description = "Public IP of NAT for private network."
#   value       = module.network.nat_ip
# }

# output "prefix" {
#   value = var.prefix
# }

# output "location" {
#   value = var.location
# }


# output "provider_account" {
#   value = data.google_client_config.current.project
# }


output "provider" {
  value = "gcp"
}

# # bastion server
# output "jump_private_ip" {
#   value = module.jump_server.private_ip
# }

# output "jump_public_ip" {
#   value = module.jump_server.public_ip
# }

# output jump_rwx_filestore_path {
#   value = var.create_jump_vm ? var.jump_rwx_filestore_path : null
# }

# output "jump_admin_username" {
#   value = module.jump_server.admin_username
# }


# # NFS server
# output "nfs_private_ip" {
#   value = var.storage_type == "standard" ? module.nfs_server.private_ip : null
# }

# output "nfs_public_ip" {
#   value = var.storage_type == "standard" ? module.nfs_server.public_ip : null
# }

# output "nfs_admin_username" {
#   value = var.storage_type == "standard" ? module.nfs_server.admin_username : null
# }

# Container regsitry
output "cr_endpoint" {
  value = "https://gcr.io/${var.project}"
}
