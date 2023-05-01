# Kubernetes Configuration File Generation

## Overview

### Notes - viya4-iac-gcp:1.0.0
The release of Kubernetes v1.19+ is dropping support for `basic authentication` via the --basic-auth-file flag. Release notes for that are [here](https://v1-19.docs.kubernetes.io/docs/setup/release/notes/#urgent-upgrade-notes)

With the removal of this feature, the generation of the kube config file for the Infrastructure as Code (IaC) repositories will now support two new options while removing the basic auth feature.

The options are:

- Provider Based
- Kubernetes Service Account and Cluster Role Binding

### Notes - viya4-iac-gcp:5.0.0

The release of kubectl v1.26 is dropping support for built-in provider-specific code in their project for authentication and instead opting for a plugin-based strategy. To quote this [Google blog post](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke): 

>To ensure the separation between the open source version of Kubernetes and those versions that are customized by services providers like Google, the open source community is requiring that all provider-specific code that currently exists in the OSS code base be removed starting with v1.26.

The options for creating the Kubernetes configuration file are still:

- Provider Based
- Kubernetes Service Account and Cluster Role Binding

However, the provider based kubernetes configuration file format will change to support the use of the `gke-gcloud-auth-plugin`. The `gke-gcloud-auth-plugin` binary is required to access any GKE clusters when using kubectl 1.26+ with a "provider based kubernetes configuration file. The "service account and cluster role binding" kubernetes configuration file variant remains the same and still does not require either `gcloud` or the `gke-gcloud-auth-plugin` binary to communicate with the cluster.

In our included Dockerfile we included steps to ensure that the plugin is installed as well as enabled. If you are opting not to this project via a Docker container produced with our Dockerfile, you will need to take steps to install both `gcloud` and `gke-gcloud-auth-plugin` on your machine. Google has provided step-by-step instructions in a blog post to aid users with this transition. See [Google's Authentication Blog post](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke).

### Provider Based - Google Cloud Provider

This option creates a kube config file that utilizes the `gcloud` and  `gke-gcloud-auth-plugin` executables from Google. This method generates a `access_token` and `token_expiry` that is stored in an authentication cache file and are refreshed each time you use the kube config file to access your cluster. This `access_token` is tied to the current authentication method used for the provider, so it's quite safe.

Portability is also limited given then file is tied to the authentication method used to create the file.

### Kubernetes Service Account and Cluster Role Binding

This options creates a static kube config file utilizing the creation of the following:

- Service Account
- Cluster Role Binding

Once created the `Service Account` is used to provide the `ca cert` and `token` embedded in the kube config file.

This file is quite portable as the `ca cert` and `token` for the cluster are static. Any who has this file can access the cluster.

## Usage

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_static_kubeconfig | Creates a static kube config file who's authentication is backed by a `Serivce Account` and `Cluster Role Binding` in your kubernetes cluster. | bool | false | Setting to `true` creates a file that easily sharable such as in a development or testing scenario |
