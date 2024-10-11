# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
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