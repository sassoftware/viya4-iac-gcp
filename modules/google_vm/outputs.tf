output "private_ip" {
  value = google_compute_instance.google_vm.network_interface.0.network_ip
}

output "public_ip" {
  value = length(module.address.addresses) > 0 ? module.address.addresses[0] : null
}

output "admin_username" {
  value = var.vm_admin
}
