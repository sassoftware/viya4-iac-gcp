resource "google_container_node_pool" "node_pool" {

  count               = var.create_node_pool ? 1 : 0

  # REQUIRED variables (must be set by caller of the module)
  name                = var.node_pool_name
  location            = var.node_pool_location
  cluster             = var.gke_cluster


  node_config {
    preemptible     = false
    machine_type    = var.machine_type
    disk_size_gb    = var.os_disk_size
    disk_type       = var.os_disk_type
    local_ssd_count = var.local_ssd_count

    labels          = var.node_labels
    taint           = var.node_taints
    tags            = [ var.gke_cluster ]
 
    oauth_scopes = [
#      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }

  node_count        = var.node_count
  autoscaling {
    min_node_count  = var.min_nodes
    max_node_count  = var.max_nodes
  }

  management {
    auto_repair = true
    auto_upgrade = true
  } 

}
