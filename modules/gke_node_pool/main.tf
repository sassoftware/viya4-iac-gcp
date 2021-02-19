locals {
  # convert k8s taint syntax into struct required by gke
  # e.g. 
  #  "workload.sas.com/class:compute:NO_SCHEDULE"
  #  into
  # { "key" : "workload.sas.com/class",
  #   "value" : "compute",
  #   "effect" : "NO_SCHEDULE" }
  #   ]
  taint_effects = { NoSchedule = "NO_SCHEDULE"
    PreferNoSchedule = "PREFER_NO_SCHEDULE"
  NoExecute = "NO_EXECUTE" }
  node_taints = [
    for taint in var.node_taints : {
      key    = split("=", split(":", taint)[0])[0]
      value  = split("=", split(":", taint)[0])[1]
      effect = local.taint_effects[split(":", taint)[1]]
    }
  ]
  autoscaling = (var.min_nodes == var.max_nodes) ? false : true

}


resource "google_container_node_pool" "node_pool" {

  # REQUIRED variables (must be set by caller of the module)
  name           = var.node_pool_name
  node_locations = var.node_locations
  cluster        = var.gke_cluster

  node_config {
    preemptible     = false
    machine_type    = var.machine_type
    disk_size_gb    = var.os_disk_size
    disk_type       = var.os_disk_type
    local_ssd_count = var.local_ssd_count

    labels = var.node_labels
    taint  = local.node_taints
    tags   = [var.gke_cluster]

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = false
  }

  node_count = local.autoscaling ? null : var.min_nodes

  initial_node_count = local.autoscaling ? var.min_nodes : null

  dynamic "autoscaling" {
    for_each = local.autoscaling ? [1] : []
    content {
      min_node_count = var.min_nodes
      max_node_count = var.max_nodes
    }
  }

  # see https://github.com/hashicorp/terraform-provider-google/issues/6901
  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}
