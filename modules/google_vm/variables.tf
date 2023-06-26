# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "name" {
  description = "Name of the VM to be created"
  type        = string
}

variable "project" {
  description = "The GCP Project to create the VM resources in"
  type        = string
}

variable "region" {
  description = "The region to create the VM in"
  type        = string
}

variable "zone" {
  description = "The zone to create the VM resources in"
  type        = string
}

variable "subnet" {
  description = "The subnetwork to configure VM network interface with"
  type        = string
}

variable "create_public_ip" {
  description = "Toggle the creation of a public IP associated with the VM"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map(any)
  default     = { project_name = "viya401", cost_center = "rnd", environment = "dev" }
}

variable "machine_type" {
  description = "Machine type of the VM to be created"
  type        = string
  default     = "n2-standard-4"
}

variable "user_data" {
  description = "Script to be run on the VM during provision time"
  type        = string
  default     = ""
}

variable "vm_admin" {
  description = "Login account for VM"
  type        = string
  default     = "googleuser"
}

variable "ssh_public_key" {
  description = "Path to ssh public key"
  type        = string
  default     = null
}

variable "os_image" {
  description = "OS Image to configure the VM with"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2004-lts" # FAMILY/PROJECT glcoud compute images list
}


variable "data_disk_count" {
  description = "Number of compute disks to associated with the VM"
  type        = number
  default     = 0
}

variable "data_disk_size" {
  description = "Size of the compute disks associated with the VM"
  type        = number
  default     = 128
}

variable "data_disk_type" {
  description = "Type of compute disk to associate with the VM"
  type        = string
  default     = "pd-ssd"
}

