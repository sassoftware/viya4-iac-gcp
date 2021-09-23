variable "prefix" {
  description = "A prefix used in the name for all cloud resources created by this script. The prefix string must start with lowercase letter and contain only lowercase alphanumeric characters and hyphen or dash(-), but can not start or end with '-'."
  validation {
    condition     = can(regex("^[a-z][-0-9a-z]*[0-9a-z]$", var.prefix))
    error_message = "ERROR: Value of 'prefix'\n * must start with lowercase letter\n * can only contain lowercase letters, numbers, and hyphen or dash(-), but can't start or end with '-'."
  }
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
  type    = string
  default = null
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
  default = "latest"

  validation {
    condition     = (can(regex("^\\d.\\d+.\\d+-gke.\\d+$", var.kubernetes_version)) || var.kubernetes_version == "latest")
    error_message = "The format for kubernetes version is: x.yy-gke.zzzz or 'latest'."
  }
}

variable "tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map
  default     = {}
}

variable "private_cluster" {
  description = "Use Private IP address for cluster API endpoint"
  type        = bool
  default     = false
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

variable "jump_vm_type" {
  description = "Jump VM type"
  default     = "n2-standard-4"
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

variable "nfs_vm_type" {
  description = "NFS VM type"
  default     = "n2-standard-4"
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

variable "minimum_initial_nodes" {
  description = "Number of initital nodes to aim for to overcome the Ingress quota limit of 100"
  default = 6
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
    accelerator_count = number
    accelerator_type = string
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
      "local_ssd_count"   = 0
      "accelerator_count" = 0
      "accelerator_type"  = ""
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
      "local_ssd_count"   = 0
      "accelerator_count" = 0
      "accelerator_type"  = ""
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
      "local_ssd_count"   = 0
      "accelerator_count" = 0
      "accelerator_type"  = ""
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
      "local_ssd_count"   = 0
      "accelerator_count" = 0
      "accelerator_type"  = ""
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
      "local_ssd_count"   = 0
      "accelerator_count" = 0
      "accelerator_type"  = ""
    }
  }
}

variable enable_cluster_autoscaling {
  description = "Setting this value will enable cluster_autoscaling"
  type        = bool
  default     = false
}

variable "cluster_autoscaling_max_cpu_cores" {
  default = 500
}

variable "cluster_autoscaling_max_memory_gb" {
  default = 10000
}

# PostgreSQL

# Defaults
variable "postgres_server_defaults" {
  description = ""
  type        = any
  default = {
    machine_type                           = "db-custom-8-30720"
    storage_gb                             = 10
    backups_enabled                        = true
    backups_start_time                     = "21:00"
    backups_location                       = null
    backups_point_in_time_recovery_enabled = false
    backup_count                           = "7" # Number of backups to retain, not days
    administrator_login                    = "pgadmin"
    administrator_password                 = "my$up3rS3cretPassw0rd"
    server_version                         = "11"
    availability_type                      = "ZONAL"
    ssl_enforcement_enabled                = true
    database_flags                         = []
  }
}

# User inputs
variable "postgres_servers" {
  description = "Map of PostgreSQL server objects"
  type        = any
  default     = null

  # Checking for user provided "default" server
  validation {
    condition = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? contains(keys(var.postgres_servers), "default") : false : true
    error_message = "ERROR: The provided map of PostgreSQL server objects does not contain the required 'default' key."
  }

  # Checking server name
  validation {
    condition = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? alltrue([
      for k,v in var.postgres_servers : alltrue([
        length(k) > 0,
        length(k) < 88,
        can(regex("^[a-z]+[a-z0-9-]*[a-zA-Z0-9]$", k)),
      ])
    ]) : false : true
    error_message = "ERROR: The database server name must start with a letter, cannot end with a hyphen, must be between 1-88 characters in length, and can only contain hyphends, letters, and numbers."
  }

  # Checking user provided login

  # Checking user provided password
}

## filstore
variable filestore_size_in_gb {
  default = null
}

variable filestore_tier {
  default = "BASIC_HDD"
  type = string
  validation {
      # we allow the old values "STANDARD" and "PREMIUM" but do not document them
      condition     = (contains(["STANDARD", "PREMIUM", "BASIC_HDD", "BASIC_SSD"], upper(var.filestore_tier)))
      error_message = "Filestore tier must be one of BASIC_HDD, BASIC_SSD."
    }
}

variable "enable_registry_access" {
  type        = bool
  description = "Enable access from GKE to the Project Container Registry."
  default     = true
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

# Network
variable "vpc_name" {
  type        = string
  default     = ""
  description = "Name of exising VPC. Leave blank to have one created"
}

variable "nat_address_name" {
  type        = string
  default     = ""
  description = "Name of existing ip address for Cloud NAT"
}

variable "subnet_names" {
  type        = map(string)
  default     = {}
  description = "Map subnet usage roles to existing subnet and secondary range names. Required when vpc_name is set."
  # Example:
  # subnet_names = {
  # gke = "my_gke_subnet"
  # gke_pods_range_name = "my_secondary_range_for_pods"
  # gke_services_range_name = "my_secondary_range_for_services"
  # misc = "my_misc_subnet"}
  # }
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

variable "filestore_subnet_cidr" {
  default = "192.168.3.0/29"
}

variable "database_subnet_cidr" {
  default = "192.168.4.0/24"
}


variable "gke_network_policy" {
  description = "Sets up network policy to be used with GKE CNI. Network policy allows us to control the traffic flow between pods. Currently supported values are true (calico) and false (kubenet). Changing this forces a new resource to be created."
  type        = bool
  default     = false
}


variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider / service account based kube config file"
  type        = bool
  default     = true
}

variable "cluster_node_pool_mode" {
  description = "Flag for predefined cluster node configurations - Values : default, minimal"
  type        = string
  default     = "default"
}
