locals {
  master_ipv4_cidr_block = "172.16.0.32/28"
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

  # default node pool
  # terraform recommends to create the default nodepool separately
  remove_default_node_pool = true
  initial_node_count       = 1

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

}

resource "google_compute_firewall" "gke-ingress" {
  name    = "${var.name}-gke-ingress"
  network = var.network

  source_ranges = [local.master_ipv4_cidr_block]

  allow {
    protocol = "tcp"
    ports    = ["8443"]
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

