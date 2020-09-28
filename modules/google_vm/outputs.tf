output "private_ip" {
  value = (var.create_vm
    ? google_compute_instance.google_vm.0.network_interface.0.network_ip
  : null)
}

output "public_ip" {
  value = (var.create_public_ip && var.create_vm
    ? element(google_compute_instance.google_vm.0.network_interface.*.access_config.0.nat_ip, 0)
  : null)
}

output "admin_username" {
  value = var.create_vm ? var.vm_admin : null
}