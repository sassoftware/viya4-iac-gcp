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

# Versions: gcloud container get-server-config
#           https://cloud.google.com/kubernetes-engine/docs/release-notes
variable "kubernetes_version" {
  default = "1.18.9-gke.1501"
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
  type    = map
  default = {}
}

variable "node_pools" {
  description = "Node pool definitions"
  type = map(object({
    machine_type    = string
    os_disk_size    = number
    min_node_count  = string
    max_node_count  = string
    node_taints     = list(string)
    node_labels     = map(string)
    local_ssd_count = number
  }))
  default = {
    cas = {
      "machine_type"   = "n1-highmem-16"
      "os_disk_size"   = 200
      "min_node_count" = 1
      "max_node_count" = 5
      "node_taints"    = ["workload.sas.com/class=cas:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "cas"
      }
      "local_ssd_count" = 0
    },
    compute = {
      "machine_type"   = "n1-highmem-16"
      "os_disk_size"   = 200
      "min_node_count" = 1
      "max_node_count" = 5
      "node_taints"    = ["workload.sas.com/class=compute:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class"        = "compute"
        "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
      "local_ssd_count" = 0
    },
    connect = {
      "machine_type"   = "n1-highmem-16"
      "os_disk_size"   = 200
      "min_node_count" = 1
      "max_node_count" = 5
      "node_taints"    = ["workload.sas.com/class=connect:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class"        = "connect"
        "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
      "local_ssd_count" = 0
    },
    stateless = {
      "machine_type"   = "e2-standard-16"
      "os_disk_size"   = 200
      "min_node_count" = 1
      "max_node_count" = 5
      "node_taints"    = ["workload.sas.com/class=stateless:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateless"
      }
      "local_ssd_count" = 0
    },
    stateful = {
      "machine_type"   = "e2-standard-8"
      "os_disk_size"   = 200
      "min_node_count" = 1
      "max_node_count" = 3
      "node_taints"    = ["workload.sas.com/class=stateful:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateful"
      }
      "local_ssd_count" = 0
    }
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

