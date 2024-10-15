# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

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
  value     = module.kubeconfig.kube_config
  sensitive = true
}

# postgres
output "postgres_servers" {
  value     = length(module.postgresql) != 0 ? local.postgres_outputs : null
  sensitive = true
}

output "rwx_filestore_endpoint" {
  description = "Shared Storage private IP"
  value = (var.storage_type == "none"
    ? null
    : var.storage_type == "ha" && var.storage_type_backend == "filestore" ? google_filestore_instance.rwx[0].networks[0].ip_addresses[0]
    : var.storage_type == "ha" && var.storage_type_backend == "netapp" ? try(module.google_netapp.mountpath, null) : module.nfs_server[0].private_ip # TODO
  )
}

output "rwx_filestore_path" {
  description = "Shared Storage mount path"
  value = (var.storage_type == "none"
    ? null
    : var.storage_type == "ha" && var.storage_type_backend == "filestore" ? "/${google_filestore_instance.rwx[0].file_shares[0].name}"
    : var.storage_type == "ha" && var.storage_type_backend == "netapp" ? try("/${module.google_netapp.mountpath}", null) : "/export"
  )
}

output "nat_ip" {
  description = "Public IP of NAT for private network."
  value       = length(var.nat_address_name) == 0 ? (length(module.nat_address[0].addresses) > 0 ? element(module.nat_address[0].addresses, 0) : null) : data.google_compute_address.nat_address[0].address
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
  value = var.create_jump_vm ? module.jump_server[0].private_ip : null
}

output "jump_public_ip" {
  value = var.create_jump_vm ? module.jump_server[0].public_ip : null
}

output "jump_rwx_filestore_path" {
  value = var.create_jump_vm ? var.jump_rwx_filestore_path : null
}

output "jump_admin_username" {
  value = var.create_jump_vm ? module.jump_server[0].admin_username : null
}

# NFS server
output "nfs_private_ip" {
  value = var.storage_type == "standard" ? module.nfs_server[0].private_ip : null
}

output "nfs_public_ip" {
  value = var.storage_type == "standard" ? module.nfs_server[0].public_ip : null
}

output "nfs_admin_username" {
  value = var.storage_type == "standard" ? module.nfs_server[0].admin_username : null
}

# Container registry
output "cr_endpoint" {
  value = var.enable_registry_access ? "https://gcr.io/${var.project}" : null
}

output "cluster_node_pool_mode" {
  value = var.cluster_node_pool_mode
}

output "cluster_api_mode" {
  value = var.cluster_api_mode
}

output "gke_pod_subnet_cidr" {
  value = var.gke_pod_subnet_cidr
}
