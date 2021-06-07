terraform {
  required_version = ">= 0.15.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.69.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "3.69.0"
    }
    kubernetes  = {
      source  = "hashicorp/kubernetes"
      version = "1.13.0" # Constrained by Google
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
      version = "2.2.0" # Constrained by Google
    }
    null = {
      source  = "hashicorp/null"
      version = "2.1.0" # Constrained by Google
    }
    external = {
      source  = "hashicorp/external"
      version = "2.1.0"
    }
  }
}
