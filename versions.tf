# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.28.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.35.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36" # Constrained by Google
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"  
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.1" # Constrained by Google
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2" # Constrained by Google
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.4" # Constrained by Google
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}
