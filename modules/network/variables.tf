variable "prefix" {
  type = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  description = "Map of tags to be placed on the Resources"
  type        = map
  default     = {}
}

# Network
variable "vpc_name" {
  type        = string
  default     = ""
  description = "Name of pre-existing VPC. Leave blank to have one created"
}
variable "subnet_names" {
  type        = map(string)
  default     = {}
  description = "Map subnet usage roles to existing subnet names"
}

variable "create_subnets" {
   type = bool
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

