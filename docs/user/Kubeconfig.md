# Kubernetes Configuration File Generation

## Overview

The release of Kubernetes v1.19+ is dropping support for `basic authentication` via the --basic-auth-file flag. Release notes for that are [here](https://v1-19.docs.kubernetes.io/docs/setup/release/notes/#urgent-upgrade-notes)

With the removal of this feature, the generation of the kube config file for the Infrastructure as Code (IaC) repositories will now support two new options while removing the basic auth feature.

The options are:

- Provider Based
- Kubernetes Service Account and Cluster Role Binding

### Provider Based - Google Cloud Provider

This option creates a kube config file that utilizes the `gcloud` executable from Google. This method generates a `token` and `expiration date` that are embedded in the kube config file and are refreshed each time you use the kube config file to access your cluster. This `token` is tied to the current authentication method used for the provider so it's quite safe.

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
