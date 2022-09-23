terraform {
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.0.0" # latest 4.37.0
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.0.0"
    }
    kubernetes  = {
      source  = "hashicorp/kubernetes"
      version = "2.13.0" # Constrained by Google
    }
    local       = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    template    = {
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
      source = "hashicorp/time"
      version = "0.8.0"
    }
  }
}
