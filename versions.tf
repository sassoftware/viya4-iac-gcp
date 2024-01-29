# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.4.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.12.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25" # Constrained by Google
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6" # Constrained by Google
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2" # Constrained by Google
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3" # Constrained by Google
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.10"
    }
  }
}
