 variable "prefix" {
  description = "A prefix used for all Google Cloud resources created by this script"
}

variable "location" {
  description = <<EOF
  The GCP Region (i.e. us-east1) or GCP Zone (i.e. us-east1-b) to provision all resources in this script. 
  Choosing a Region will make this a multi-zonal cluster. 
  If you aren't sure which to choose, go with a ZONE instead of a region. 
  If not set, it defaults to the google environment variables, as documented in https://www.terraform.io/docs/providers/google/guides/provider_reference.html"
  EOF
}

variable "regional" {
  description = "Should the GKE cluster have a regional or zonal control plane"
  type        = bool
  default     = true
}

variable "service_account_keyfile" {
  type = string
}

variable "project" {
  type = string
}

variable "iac_tooling" {
  description = "Value used to identify the tooling used to generate this providers infrastructure."
  type        = string
  default     = "terraform"
}

## Channel - UNSPECIFIED/STABLE/REGULAR/RAPID - RAPID is currently the only channel that supports k8s v1.18
variable "kubernetes_channel" {
  default = "UNSPECIFIED"
}

# Google Cloud will utilize the current default value for the given channel.
# A specific version can be provided to override the default.
# Available Versions: gcloud container get-server-config
#                     https://cloud.google.com/kubernetes-engine/docs/release-notes
variable "kubernetes_version" {
  default = "1.18.16-gke.1200"

  validation {
    condition     = (can(regex("^\\d.\\d+.\\d+-gke.\\d+$", var.kubernetes_version)) || var.kubernetes_version == "latest")
    error_message = "The format for kuberentes version is: x.yy-gke.zzzz or 'latest'."
  }
}

variable "tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map
  default     = {}
}

variable "default_public_access_cidrs" {
  description = "List of CIDRs to access created resources"
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster"
  type        = list(string)
  default     = null
}

variable "vm_public_access_cidrs" {
  description = "List of CIDRs to access jump or nfs VM"
  type        = list(string)
  default     = null
}

variable "postgres_public_access_cidrs" {
  description = "List of CIDRs to access PostgreSQL server"
  type        = list(string)
  default     = null
}

variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}

# Bastion VM
variable "create_jump_vm" {
  type    = bool
  default = true
}

variable "jump_vm_admin" {
  description = "OS Admin User for Bastion VM"
  default     = "jumpuser"
}

variable "create_jump_public_ip" {
  default = true
}

variable "jump_rwx_filestore_path" {
  description = "OS path used for NFS integration"
  default     = "/viya-share"
}

# NFS VM
variable "nfs_vm_admin" {
  description = "OS Admin User for NFS VM"
  default     = "nfsuser"
}

variable "nfs_raid_disk_size" {
  description = "Size in Gb for each disk of the RAID5 cluster"
  default     = 128
}

variable "create_nfs_public_ip" {
  default = false
}

variable "storage_type" {
  type    = string
  default = "standard"

  validation {
    condition     = contains(["standard", "ha"], lower(var.storage_type))
    error_message = "ERROR: Supported value for `storage_type` are - standard, ha."
  }
}

# Default Node pool config
variable "default_nodepool_vm_type" {
  default = "e2-standard-8"
}

variable "default_nodepool_local_ssd_count" {
  default = 0
}

variable "default_nodepool_os_disk_size" {
  default = 128
}

variable "default_nodepool_max_nodes" {
  default = 5
}

variable "default_nodepool_min_nodes" {
  default = 1
}

variable "default_nodepool_taints" {
  type    = list
  default = []
}

variable "default_nodepool_labels" {
  type    = map
  default = {}
}

variable "node_pools" {
  description = "Node pool definitions"
  type = map(object({
    vm_type         = string
    os_disk_size    = number
    min_nodes       = string
    max_nodes       = string
    node_taints     = list(string)
    node_labels     = map(string)
    local_ssd_count = number
  }))
  default = {
    cas = {
      "vm_type"      = "n1-highmem-16"
      "os_disk_size" = 200
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "cas"
      }
      "local_ssd_count" = 0
    },
    compute = {
      "vm_type"      = "n1-highmem-16"
      "os_disk_size" = 200
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class"        = "compute"
        "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
      "local_ssd_count" = 0
    },
    connect = {
      "vm_type"      = "n1-highmem-16"
      "os_disk_size" = 200
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=connect:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class"        = "connect"
        "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
      "local_ssd_count" = 0
    },
    stateless = {
      "vm_type"      = "e2-standard-16"
      "os_disk_size" = 200
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateless"
      }
      "local_ssd_count" = 0
    },
    stateful = {
      "vm_type"      = "e2-standard-8"
      "os_disk_size" = 200
      "min_nodes"    = 1
      "max_nodes"    = 3
      "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateful"
      }
      "local_ssd_count" = 0
    }
  }
}

variable "cluster_autoscaling_max_cpu_cores" {
  default = 500
}

variable "cluster_autoscaling_max_memory_gb" {
  default = 10000
}

## PostgresSQL inputs
variable "create_postgres" {
  description = "Create a PostgreSQL Server instance"
  type        = bool
  default     = false
}

variable "postgres_name" {
  description = "The name of the PostgreSQL Server. Changing this forces a new resource to be created."
  default     = ""
}

variable "postgres_machine_type" {
  description = "The machine type to use. Postgres supports only shared-core machine types such as db-f1-micro, and custom machine types such as db-custom-2-13312."
  default     = "db-custom-8-30720"
}

variable "postgres_storage_gb" {
  description = "Min storage for the PostgreSQL Server instance."
  default     = 10
}

variable "postgres_administrator_login" {
  description = "The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created."
  default     = "pgadmin"
}

variable "postgres_administrator_password" {
  description = "The password for the postgres_administrator_login ID"
  default     = ""
}

variable "postgres_server_version" {
  description = "The version of PostgreSQL to use. Valid values are 9.6, 10, 11, and 12."
  default     = "11"
}

variable "postgres_ssl_enforcement_enabled" {
  description = "Enforce SSL on connections."
  default     = true
}

variable "postgres_db_charset" {
  description = "Charset for the PostgreSQL Database. Needs to be a valid PostgreSQL Charset. Changing this forces a new resource to be created."
  default     = "UTF8"
}

variable "postgres_db_collation" {
  description = "Collation for the PostgreSQL Database."
  default     = "en_US.UTF8"
}

variable "postgres_backups_enabled" {
  default = true
}

variable "postgres_backups_start_time" {
  default = "21:00"
}

variable "postgres_backups_location" {
  default = null
}

variable "postgres_backups_point_in_time_recovery_enabled" {
  default = false
}

variable "postgres_db_names" {
  description = "The list of names of PostgreSQL database to create. Needs to be a valid PostgreSQL identifier. Changing this forces a new resource to be created."
  default     = []
}

variable "postgres_availability_type" {
  default = "ZONAL"
}

variable "postgres_database_flags" {
  type = list(object({
    name = string
    value = string
  }))

  default = [
    { 
      # 30Gb RAM needed to get 600 max_connections (https://cloud.google.com/sql/docs/postgres/quotas#cloud-sql-for-postgresql-connection-limits)
      name = "max_connections"
      value = 600
    },
    { 
      name = "max_prepared_transactions"
      value = 1024
    },
  ]
}

variable "gke_subnet_cidr" {
  default = "192.168.0.0/23"
}

variable "misc_subnet_cidr" {
  default = "192.168.2.0/24"
}

variable "gke_pod_subnet_cidr" {
  default = "10.0.0.0/17"
}

variable "gke_service_subnet_cidr" {
  default = "10.1.0.0/22"
}

variable "gke_control_plane_subnet_cidr" {
  default = "10.2.0.0/28"
}

variable "gke_network_policy" {
  description = "Sets up network policy to be used with GKE CNI. Network policy allows us to control the traffic flow between pods. Currently supported values are true (calico) and false (kubenet). Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

## filstore
variable filestore_size_in_gb {
  default = 1024
}

variable filestore_tier {
  default = "STANDARD"
}

variable "create_container_registry" {
  type        = bool
  description = "Boolean flag to create container registry"
  default     = false
}

# Azure Monitor
variable "create_gke_monitoring_service" {
  type        = bool
  description = "Enable GKE metrics from pods in the cluster to the Google Cloud Monitoring API."
  default     = "false"
}

variable "gke_monitoring_service" {
  type        = string
  description = "Value of the Google Cloud Monitoring API to use if monitoring is enabled. Values are: monitoring.googleapis.com, monitoring.googleapis.com/kubernetes, none"
  default     = "none"
}

variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider / service account based kube config file"
  type        = bool
  default     = false
}
