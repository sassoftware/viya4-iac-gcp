# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "prefix" {
  description = "A prefix used for all Google Cloud resources created by this script"
  type        = string
}

variable "namespace" {
  description = "Namespace that the service account and cluster role binding will placed."
  type        = string
  default     = "kube-system"
}

variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider / service account based kube config file"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Cluster name provided by GKE module"
  type        = string
  default     = null
}

variable "cluster_endpoint" {
  description = "Cluster endpoint provided by GKE module"
  type        = string
  default     = null
}

variable "cluster_ca_cert" {
  description = "Cluster CA certificate provided by GKE module"
  type        = string
  default     = null
}
