# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "prefix" {
  description = "A prefix used in the name for all cloud resources created by this script. The prefix string must start with lowercase letter and contain only lowercase alphanumeric characters and hyphen or dash(-), but can not start or end with '-'."
  type        = string
}

variable "region" {
  description = "The region to create the VM in"
  type        = string
}

variable "service_level" {
  description = "Service level of the storage pool. Possible values are: PREMIUM, EXTREME, STANDARD, FLEX."
  type        = string
  default     = "PREMIUM"
}

variable "protocols" {
  description = "The target volume protocol expressed as a list. Allowed combinations are ['NFSV3'], ['NFSV4'], ['SMB'], ['NFSV3', 'NFSV4'], ['SMB', 'NFSV3'] and ['SMB', 'NFSV4']. Each value may be one of: NFSV3, NFSV4, SMB."
  type        = list(string)
  default     = ["NFSV3"]
}

variable "capacity_gib" {
  description = "Capacity of the storage pool (in GiB)."
  type        = string
  default     = 2048
}

variable "volume_path" {
  description = "A unique file path for the volume. Used when creating mount targets. Needs to be unique per location."
  type        = string
  default     = "export"
}

variable "network" {
  description = "VPC network name with format: `projects/{{project}}/global/networks/{{network}}`"
  type        = string
}


variable "allowed_clients" {
  description = "CIDR blocks allowed to mount nfs exports"
  type        = string
  default     = "0.0.0.0/0"
}

variable "netapp_subnet_cidr" {
  description = "Address space for Google Cloud NetApp Volumes subnet"
  type        = string
  default     = "192.168.5.0/24"
}

# Community Contribution
variable "community_netapp_networking_components_enabled" {
  description = "Community Contribution. Enable/Disable the deployment of Networking components for Netapp resources. Enabled by default."
  type        = bool
  default     = true
}