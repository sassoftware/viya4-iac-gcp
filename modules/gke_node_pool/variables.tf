# REQUIRED variables (must be set by caller of the module)
variable "node_pool_name" {}
variable "node_locations" {}
variable "gke_cluster" {}

# OPTIONAL variables (these have defaults)
variable "machine_type" {
  default = "n1-standard-1"
}

variable "initial_node_count" {
  default = 1
}

variable "max_nodes" {
  default = 10
}

variable "min_nodes" {
  default = 1
}

variable "node_taints" {
  type    = list
  default = []
}

variable "node_labels" {
  type    = map
  default = {}
}

variable "tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map
  default     = {}
}

variable "local_ssd_count" {
  default = 0
}

variable "os_disk_size" {
  default = 100
}

variable "os_disk_type" {
  default = "pd-standard"
  # "pd-ssd" is only other option
}
