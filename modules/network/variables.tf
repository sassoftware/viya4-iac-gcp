# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

# Network
variable "vpc_name" {
  description = "Name of pre-existing VPC. Leave blank to have one created"
  type        = string
  default     = ""
}
variable "subnet_names" {
  description = "Map subnet usage roles to existing subnet names"
  type        = map(string)
  default     = {}
}

variable "create_subnets" {
  type = bool
}

variable "gke_subnet_cidr" {
  type = string
  default = "192.168.0.0/23"
}

variable "misc_subnet_cidr" {
  type = string
  default = "192.168.2.0/24"
}

variable "gke_pod_subnet_cidr" {
  type = string
  default = "10.0.0.0/17"
}

variable "gke_service_subnet_cidr" {
  type = string
  default = "10.1.0.0/22"
}
