output "ip" {
  description = "Private IP for Google Filestore Instance"
  value =  element(coalescelist(google_filestore_instance.rwx.*.networks.0.ip_addresses.0,[""]),0)
}

output "mount_path"{
   description = "Google Filestore mount path"
   value = element(coalescelist(google_filestore_instance.rwx.*.file_shares.0.name,[""]),0)
}
