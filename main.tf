provider "google" {
  credentials = file(var.service_account_keyfile)
  project     = var.project
}

provider "google-beta" {
  credentials = file(var.service_account_keyfile)
  project     = var.project
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token                  = data.google_client_config.current.access_token
  load_config_file       = false
}

resource "random_id" "username" {
  byte_length = 14
}

resource "random_password" "password" {
  length = 24
  special = true
  number = true
  upper = true
}

data "template_file" "kubeconfig" {
  template = file("${path.module}/files/kubeconfig.tmpl")

  vars = {
    cluster_name  = module.gke.name
    endpoint      = module.gke.endpoint
    user_name     = random_id.username.hex
    user_password = random_password.password.result
    cluster_ca    = module.gke.ca_certificate
  }
}

resource "local_file" "kubeconfig" {
  content              = data.template_file.kubeconfig.rendered
  filename             = local.kubeconfig_path
  file_permission      = "0644"
  directory_permission = "0755"
}

data "google_client_config" "current" {}

# Used for locals below.
data "google_compute_zones" "available" {
  region = local.region
}

locals {

  # get the region from "location", or else from the local config
  region = var.location != "" ? regex("^[a-z0-9]*-[a-z0-9]*", var.location) : data.google_client_config.current.region

  # get the zone from "location", or else from the local config. If none is set, default to the first zone in the region
  is_region  = var.location != "" ? var.location == regex("^[a-z0-9]*-[a-z0-9]*", var.location) : false
  first_zone = length(data.google_compute_zones.available.names) > 0 ? data.google_compute_zones.available.names[0] : ""
  zone       = ( var.location != "" ? (local.is_region ? local.first_zone : var.location) : (data.google_client_config.current.zone == "" ? local.first_zone : data.google_client_config.current.zone) )
  location   = var.location != "" ? var.location : local.zone

  default_public_access_cidrs          = var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs
  vm_public_access_cidrs               = var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs
  postgres_public_access_cidrs         = var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs

  ssh_public_key = file(var.ssh_public_key)

  kubeconfig_path     = var.iac_tooling == "docker" ? "/workspace/${var.prefix}-gke-kubeconfig.conf" : "${var.prefix}-gke-kubeconfig.conf"

  taint_effects = { 
    NoSchedule       = "NO_SCHEDULE"
    PreferNoSchedule = "PREFER_NO_SCHEDULE"
    NoExecute        = "NO_EXECUTE"
  }

  node_pools = merge(var.node_pools, {
    default = {
      "vm_type"      = var.default_nodepool_vm_type
      "os_disk_size" = var.default_nodepool_os_disk_size
      "min_nodes"    = var.default_nodepool_min_nodes
      "max_nodes"    = var.default_nodepool_max_nodes
      "node_taints"  = var.default_nodepool_taints
      "node_labels" = merge(var.tags, var.default_nodepool_labels,{"kubernetes.azure.com/mode"="system"})
      "local_ssd_count" = var.default_nodepool_local_ssd_count
    }
  })

}

data "external" "git_hash" {
  program = ["files/iac_git_info.sh"]
}

data "external" "iac_tooling_version" {
  program = ["files/iac_tooling_version.sh"]
}

resource "kubernetes_config_map" "sas_iac_buildinfo" {
  metadata {
    name      = "sas-iac-buildinfo"
    namespace = "kube-system"
  }

  data = {
    git-hash    = lookup(data.external.git_hash.result, "git-hash")
    timestamp   = chomp(timestamp())
    iac-tooling = var.iac_tooling
    terraform   = <<EOT
version: ${lookup(data.external.iac_tooling_version.result, "terraform_version")}
revision: ${lookup(data.external.iac_tooling_version.result, "terraform_revision")}
provider-selections: ${lookup(data.external.iac_tooling_version.result, "provider_selections")}
outdated: ${lookup(data.external.iac_tooling_version.result, "terraform_outdated")}
EOT
  }

  depends_on = [ module.gke ]
}

resource "google_filestore_instance" "rwx" {
  name   = "${var.prefix}-rwx-filestore"
  count  = var.storage_type == "ha" ? 1 : 0 
  tier   = var.filestore_tier
  zone   = local.zone
  labels = var.tags

  file_shares {
    capacity_gb = var.filestore_size_in_gb
    name        = "volumes"
  }

  networks {
    network = module.vpc.network_name
    modes   = ["MODE_IPV4"]
  }
}

data "google_container_engine_versions" "gke-version" {
  provider = google-beta
  location       = local.location
  version_prefix = "${var.kubernetes_version}."
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                    = "13.1.0"
  project_id                 = var.project
  name                       = "${var.prefix}-gke"
  region                     = local.region
  # TODO: add var for user to change cluster to zonal
  regional                   = true
  zones                      = [local.zone]
  network                    = module.vpc.network_name
  subnetwork                 = module.vpc.subnets_names[0]
  ip_range_pods              = "${var.prefix}-gke-pods"
  ip_range_services          = "${var.prefix}-gke-services"
  http_load_balancing        = false
  horizontal_pod_autoscaling = true
  enable_private_endpoint    = false
  enable_private_nodes       = true
  ## TODO add var to change master cidr block
  master_ipv4_cidr_block     = "10.2.0.0/28"

  add_cluster_firewall_rules = true

  ## TODO remove basic auth
  basic_auth_username        = random_id.username.hex
  basic_auth_password        = random_password.password.result
  kubernetes_version         = data.google_container_engine_versions.gke-version.latest_master_version

  # TODO: add var for user to disable/enable network policy (calico)
  network_policy             = false
  remove_default_node_pool	 = true

  # TODO: logic to enable registy access if gcp enabled
  grant_registry_access      = true

  # TODO: add var for setting monitoring
  monitoring_service         = "none"

  # TODO cluster autscaler
  cluster_autoscaling        = { "enabled": true, "max_cpu_cores": 1, "max_memory_gb": 1, "min_cpu_cores": 1, "min_memory_gb": 1 }

  master_authorized_networks = concat([
    for cidr in (var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs): {
      display_name = cidr
      cidr_block   = cidr
    }], [{
      display_name  = "VPC"
      cidr_block    = data.google_compute_subnetwork.subnetwork.ip_cidr_range
  }])

  node_pools = [
    for nodepool, settings in local.node_pools: {
      name               = nodepool
      machine_type       = settings.vm_type
      node_locations     = local.location
      min_count          = settings.min_nodes
      max_count          = settings.max_nodes
      local_ssd_count    = settings.local_ssd_count
      disk_size_gb       = settings.os_disk_size
      auto_repair        = false
      auto_upgrade       = false
      preemptible        = false
      disk_type          = "pd-standard"
      image_type         = "COS"
    }
  ]

  node_pools_oauth_scopes = {
    all = [   
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    for nodepool, settings in local.node_pools: nodepool => settings.node_labels
  }

  node_pools_taints = {
    for nodepool, settings in local.node_pools: nodepool => [
      for taint in settings.node_taints: {
        key = split("=", split(":", taint)[0])[0]
        value  = split("=", split(":", taint)[0])[1]
        effect = local.taint_effects[split(":", taint)[1]]
      }
    ]
  }

  depends_on = [data.google_compute_subnetwork.subnetwork]
}

module "sql_db_postgresql" {
  providers = {
    google-beta = google-beta
  }
  source                           = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version                          = "4.5.0"
  project_id                       = var.project
  
  name                             = lower("${var.prefix}-pgsql") 
  random_instance_name             = true // Need this because of this: https://cloud.google.com/sql/docs/mysql/delete-instance
  count                            = var.create_postgres ? 1 : 0
  zone                             = local.zone

  region                           = regex("^[a-z0-9]*-[a-z0-9]*", var.location)
  availability_type                = var.postgres_availability_type

  deletion_protection              = false
  module_depends_on                = [google_service_networking_connection.private_vpc_connection]

  tier                             = var.postgres_machine_type 
  disk_size                        = var.postgres_storage_gb

  enable_default_db                = false
  user_name                        = var.postgres_administrator_login
  user_password                    = var.postgres_administrator_password
  user_labels                      = var.tags

  database_version                 = "POSTGRES_${var.postgres_server_version}"
  database_flags                   = var.postgres_database_flags
  db_charset                       = var.postgres_db_charset
  db_collation                     = var.postgres_db_collation

  backup_configuration = {
    enabled                        = var.postgres_backups_enabled
    start_time                     = var.postgres_backups_start_time
    location                       = var.postgres_backups_location
    point_in_time_recovery_enabled = var.postgres_backups_point_in_time_recovery_enabled
  }

  ip_configuration  = {
    private_network = module.vpc.network_self_link
    require_ssl     = var.postgres_ssl_enforcement_enabled

    ipv4_enabled = length(local.postgres_public_access_cidrs) > 0 ? true : false
    authorized_networks = [
      for cidr in var.postgres_public_access_cidrs: {
        value = cidr
      }
    ]
  }

  additional_databases = [
    for db in var.postgres_db_names: {
      name = db
      charset = var.postgres_db_charset
      collation = var.postgres_db_collation
    }
  ]
}
