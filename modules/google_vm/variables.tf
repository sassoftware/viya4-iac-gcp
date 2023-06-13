# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "name" {
  type = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "subnet" {
  type = string
}

variable "create_public_ip" {
  type = bool
  default = false
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
  default     = { project_name = "viya401", cost_center = "rnd", environment = "dev" }
}

variable "machine_type" {
  type = string
  default = "n2-standard-4"
}

variable "user_data" {
  type = string
  default = ""
}

variable "vm_admin" {
  description = "Login account for VM"
  type = string
  default     = "googleuser"
}

variable "ssh_public_key" {
  description = "Path to ssh public key"
  type = string
  default     = null
}

variable "os_image" {
  type = string
  default = "ubuntu-os-cloud/ubuntu-2004-lts" # FAMILY/PROJECT glcoud compute images list
}


variable "data_disk_count" {
  type = number
  default = 0
}

variable "data_disk_size" {
  type = number
  default = 128
}

variable "data_disk_type" {
  type = string
  default = "pd-ssd"
}

