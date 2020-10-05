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

variable "service_account_keyfile" {
  type = string
}

variable "project" {
  type = string
}

variable "kubernetes_version" {
  default = "1.18.6-gke.4801"
}

## Channel - UNSPECIFIED/STABLE/REGULAR/RAPID - RAPID is currently the only channel that supports k8s v1.18
variable "kubernetes_channel" {
  default = "RAPID"
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
  default = null # the actual default depends on the value for storage_type and is being calculated as local.create_jump_vm
}

variable "jump_vm_admin" {
  description = "OS Admin User for Bastion VM"
  default     = "jumpuser"
}

variable "create_jump_public_ip" {
  default = true
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
  default = "n1-standard-1"
}

variable "default_nodepool_local_ssd_count" {
  default = 0
}

variable "default_nodepool_os_disk_size" {
  default = 128
}

variable "default_nodepool_node_count" {
  default = 2
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
  type = map
  default = {
  }
}

# CAS Node pool config
variable "create_cas_nodepool" {
  description = "Create the CAS Node Pool"
  type        = bool
  default     = true
}

variable "cas_nodepool_vm_type" {
  default = "n1-highmem-16"
}

variable "cas_nodepool_local_ssd_count" {
  default = 0
}

variable "cas_nodepool_os_disk_size" {
  default = 200
}

variable "cas_nodepool_node_count" {
  default = 1
}

variable "cas_nodepool_max_nodes" {
  default = 5
}

variable "cas_nodepool_min_nodes" {
  default = 1
}

variable "cas_nodepool_taints" {
  type = list
  default = [{ "key" : "workload.sas.com/class",
    "value" : "cas",
  "effect" : "NO_SCHEDULE" }]
}

variable "cas_nodepool_labels" {
  type = map
  default = {
    "workload.sas.com/class" = "cas"
  }
}

# compute Node pool config
variable "create_compute_nodepool" {
  description = "Create the Compute Node Pool"
  type        = bool
  default     = true
}

variable "compute_nodepool_vm_type" {
  default = "n1-highmem-16"
}

variable "compute_nodepool_local_ssd_count" {
  default = 0
}

variable "compute_nodepool_os_disk_size" {
  default = 200
}

variable "compute_nodepool_node_count" {
  default = 1
}

variable "compute_nodepool_max_nodes" {
  default = 5
}

variable "compute_nodepool_min_nodes" {
  default = 1
}

variable "compute_nodepool_taints" {
  type = list
  default = [{ "key" : "workload.sas.com/class",
    "value" : "compute",
  "effect" : "NO_SCHEDULE" }]
}

variable "compute_nodepool_labels" {
  type = map
  default = {
    "workload.sas.com/class"        = "compute"
    "launcher.sas.com/prepullImage" = "sas-programming-environment"
  }
}

# connect Node pool config
variable "create_connect_nodepool" {
  description = "Create the Connect Node Pool"
  type        = bool
  default     = true
}

variable "connect_nodepool_vm_type" {
  default = "n1-highmem-16"
}

variable "connect_nodepool_local_ssd_count" {
  default = 0
}

variable "connect_nodepool_os_disk_size" {
  default = 200
}

variable "connect_nodepool_node_count" {
  default = 1
}

variable "connect_nodepool_max_nodes" {
  default = 5
}

variable "connect_nodepool_min_nodes" {
  default = 1
}

variable "connect_nodepool_taints" {
  type = list
  default = [{ "key" : "workload.sas.com/class",
    "value" : "connect",
  "effect" : "NO_SCHEDULE" }]
}

variable "connect_nodepool_labels" {
  type = map
  default = {
    "workload.sas.com/class"        = "connect"
    "launcher.sas.com/prepullImage" = "sas-programming-environment"
  }
}

# Stateless Node pool config
variable "create_stateless_nodepool" {
  description = "Create the Stateless Node Pool"
  type        = bool
  default     = true
}

variable "stateless_nodepool_vm_type" {
  default = "e2-standard-16"
}

variable "stateless_nodepool_local_ssd_count" {
  default = 0
}

variable "stateless_nodepool_os_disk_size" {
  default = 200
}

variable "stateless_nodepool_node_count" {
  default = 1
}

variable "stateless_nodepool_max_nodes" {
  default = 5
}

variable "stateless_nodepool_min_nodes" {
  default = 1
}

variable "stateless_nodepool_taints" {
  type = list
  default = [{ "key" : "workload.sas.com/class",
    "value" : "stateless",
  "effect" : "NO_SCHEDULE" }]
}

variable "stateless_nodepool_labels" {
  type = map
  default = {
    "workload.sas.com/class" = "stateless"
  }
}

# Stateful Node pool config
variable "create_stateful_nodepool" {
  description = "Create the Stateful Node Pool"
  type        = bool
  default     = true
}

variable "stateful_nodepool_vm_type" {
  default = "e2-standard-8"
}

variable "stateful_nodepool_local_ssd_count" {
  default = 0
}

variable "stateful_nodepool_os_disk_size" {
  default = 200
}

variable "stateful_nodepool_node_count" {
  default = 1
}

variable "stateful_nodepool_max_nodes" {
  default = 3
}

variable "stateful_nodepool_min_nodes" {
  default = 1
}

variable "stateful_nodepool_taints" {
  type = list
  default = [{ "key" : "workload.sas.com/class",
    "value" : "stateful",
  "effect" : "NO_SCHEDULE" }]
}

variable "stateful_nodepool_labels" {
  type = map
  default = {
    "workload.sas.com/class" = "stateful"
  }
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
  default     = null
}

variable "postgres_server_version" {
  description = "The version of PostgreSQL to use. Valid values are 9.6, 10, 11, and 12."
  default     = "11"
}

variable "postgres_ssl_enforcement_enabled" {
  description = "Enforce SSL on connections."
  default     = true
}

