# RWX file store
resource "google_filestore_instance" "rwx" {
  name   = var.name
  count  = var.create_filestore ? 1 : 0 
  tier   = "STANDARD"
  zone   = var.zone
  labels = var.labels

  file_shares {
    capacity_gb = var.capacity
    name        = "volumes"
  }

  networks {
    network = var.network
    modes   = ["MODE_IPV4"]
  }
}
