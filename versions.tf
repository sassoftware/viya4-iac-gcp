# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.38.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.38.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.14.0" # Constrained by Google
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0" # Constrained by Google
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0" # Constrained by Google
    }
    external = {
      source  = "hashicorp/external"
      version = "2.2.2" # Constrained by Google
    }
    time = {
      source  = "hashicorp/time"
      version = "0.8.0"
    }
  }
}
