output "mountpath" {
  value = google_netapp_volume.netapp-nfs-volume.mount_options[0].export
}

output "export_ip" {
  value = split(":", google_netapp_volume.netapp-nfs-volume.mount_options[0].export_full)[0]
}

output "dns_hostname" {
  description = "DNS hostname for the NetApp volume endpoint (when DNS is enabled)"
  value       = var.enable_netapp_dns && local.is_multizone ? "${var.netapp_dns_hostname}.${var.netapp_dns_zone_name}" : null
}

output "dns_zone_name" {
  description = "Private DNS zone name for NetApp endpoint"
  value       = var.enable_netapp_dns && local.is_multizone ? var.netapp_dns_zone_name : null
}

output "endpoint" {
  description = "NetApp volume endpoint - DNS hostname if enabled, otherwise IP address"
  value       = var.enable_netapp_dns && local.is_multizone ? "${var.netapp_dns_hostname}.${var.netapp_dns_zone_name}" : split(":", google_netapp_volume.netapp-nfs-volume.mount_options[0].export_full)[0]
}
