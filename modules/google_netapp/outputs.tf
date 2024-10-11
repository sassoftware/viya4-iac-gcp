output "mountpath" {
  value = google_netapp_volume.my-nfsv3-volume.mount_options[0].export_full
}
