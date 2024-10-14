output "mountpath" {
  value = google_netapp_volume.netapp-nfs-volume.mount_options[0].export_full
}
