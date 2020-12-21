locals {
  master_ipv4_cidr_block = "172.16.0.32/28"
  # convert k8s taint syntax into struct required by tf
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
  default_nodepool_taints = [
    for taint in var.default_nodepool_taints : {
      key    = split("=", split(":", taint)[0])[0]
      value  = split("=", split(":", taint)[0])[1]
      effect = local.taint_effects[split(":", taint)[1]]
    }
  ]
  default_nodepool_autoscaling = var.default_nodepool_min_nodes == var.default_nodepool_max_nodes ? false : true
}

resource "google_container_cluster" "primary" {
  # REQUIRED variables (must be set by caller of the module)
  name            = var.name
  location        = var.location
  resource_labels = var.labels
  network         = var.network
  subnetwork      = var.subnet


  # Kubernetes channel and version
  release_channel {
    channel = var.kubernetes_channel
  }
  min_master_version = var.kubernetes_version

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.endpoint_access
      content {
        cidr_block = cidr_blocks.value
      }
    }
  }

  # create the nodes without public ips
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = local.master_ipv4_cidr_block
  }

  master_auth {
    username = random_id.username.hex
    password = random_id.password.hex
    client_certificate_config {
      issue_client_certificate = false
    }

  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block = var.pod_cidr_block
  }

  initial_node_count       = var.default_nodepool_create ? 0 : 1
  remove_default_node_pool = var.default_nodepool_create ? false : true

  dynamic "node_pool" {
    for_each = var.default_nodepool_create ? [0] : []
    content {
      name = "default"
      node_config {
        preemptible     = false
        machine_type    = var.default_nodepool_vm_type
        disk_size_gb    = var.default_nodepool_os_disk_size
        disk_type       = var.default_nodepool_os_disk_type
        local_ssd_count = var.default_nodepool_local_ssd_count
        labels          = merge(var.labels, var.default_nodepool_labels)
        taint           = local.default_nodepool_taints
        tags            = [var.name]
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
        auto_upgrade = true
      }
      node_count         = local.default_nodepool_autoscaling ? null : var.default_nodepool_min_nodes
      initial_node_count = local.default_nodepool_autoscaling ? var.default_nodepool_min_nodes : null
      dynamic "autoscaling" {
        for_each = local.default_nodepool_autoscaling ? [1] : []
        content {
          min_node_count = var.default_nodepool_min_nodes
          max_node_count = var.default_nodepool_max_nodes
        }
      }
    }
  }

  dynamic "node_pool" {
    for_each = var.node_pools
    content {
      name = node_pool.key
      node_config {
        preemptible     = false
        machine_type    = node_pool.value["vm_type"]
        disk_size_gb    = node_pool.value["os_disk_size"]
        disk_type       = "pd-standard"
        local_ssd_count = node_pool.value["local_ssd_count"]

        labels = node_pool.value["node_labels"]
        taint = [for taint in node_pool.value["node_taints"] : {
          key    = split("=", split(":", taint)[0])[0]
          value  = split("=", split(":", taint)[0])[1]
          effect = local.taint_effects[split(":", taint)[1]]
          }
        ]
        tags = [var.name]

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
        auto_upgrade = true
      }

      node_count         = ((node_pool.value["min_nodes"] == node_pool.value["max_nodes"]) ? false : true) ? null : node_pool.value["min_nodes"]
      initial_node_count = ((node_pool.value["min_nodes"] == node_pool.value["max_nodes"]) ? false : true) ? node_pool.value["min_nodes"] : null
      dynamic "autoscaling" {
        for_each = ((node_pool.value["min_nodes"] == node_pool.value["max_nodes"]) ? false : true) ? [1] : []
        content {
          min_node_count = node_pool.value["min_nodes"]
          max_node_count = node_pool.value["max_nodes"]
        }
      }
    }
  }

  #see https://github.com/hashicorp/terraform-provider-google/issues/6901
  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }


}

data "template_file" "kubeconfig" {
  template = file("${path.module}/kubeconfig-template.yaml")

  vars = {
    cluster_name  = google_container_cluster.primary.name
    endpoint      = google_container_cluster.primary.endpoint
    user_name     = google_container_cluster.primary.master_auth[0].username
    user_password = google_container_cluster.primary.master_auth[0].password
    cluster_ca    = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  }

}

resource "random_id" "username" {
  byte_length = 14
}

resource "random_id" "password" {
  byte_length = 16
}

