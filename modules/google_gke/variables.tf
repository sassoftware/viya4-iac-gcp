variable "name" {}
variable "location" {}
variable "kubernetes_version" {}
variable "kubernetes_channel" {}
variable "labels" {}
variable "network" {}
variable "subnet" {}
variable "endpoint_access" {}
variable "pod_cidr_block" {}

variable "default_nodepool_vm_type" {
  default = "e2-medium"
}

variable "default_nodepool_node_count" {
  default = 3
}

variable "default_nodepool_max_nodes" {
  default = 10
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

variable "default_nodepool_local_ssd_count" {
  default = 0
}
variable "default_nodepool_os_disk_size" {
  default = 100
}

variable "default_nodepool_os_disk_type" {
  default = "pd-standard"
}

variable "default_nodepool_create" {
  default = false
}

variable "node_pools" {
}
