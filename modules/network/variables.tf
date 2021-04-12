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
  default     = null
  description = "Name of pre-exising VPC. Leave blank to have one created"
}

variable "firewall_rule_name" {
  type        = string
  default     = null
  description = "Name of pre-exising firewall rul. Leave blank to have one created"
}

variable "subnet_names" {
  type        = map(string)
  default     = null
  description = "Map subnet usage roles to existing subnet names"
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

