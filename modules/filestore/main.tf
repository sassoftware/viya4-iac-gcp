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


/*
provider "helm" {
  version = "~> 1.2"

  kubernetes {
    load_config_file       = false
    host                   = var.host
    token                  = var.access_token
  
    cluster_ca_certificate = var.cluster_ca_certificate
  }
}

resource "helm_release" "rwx-provisioner" {
  name  = "nfs-client"
  chart = "stable/nfs-client-provisioner"
  
  set {
    name  = "nfs.server"
    value = google_filestore_instance.rwx.networks[0].ip_addresses[0]
  }

  set {
    name  = "nfs.path"
    value = "/volumes"
  }
}
*/
