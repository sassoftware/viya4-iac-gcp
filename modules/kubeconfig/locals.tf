# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Local variables
locals {

  # Kubernetes object name based on user provided `prefix` value
  service_account_name        = "${var.prefix}-cluster-admin-sa"
  cluster_role_binding_name   = "${var.prefix}-cluster-admin-crb"
  service_account_secret_name = "${var.prefix}-sa-secret"

  # Service account secret token
#  sa_secret_token = lookup(kubernetes_secret.sa_secret.0.data, "token", "") # TODO CLEANUP
  sa_secret_token = var.create_static_kubeconfig ? lookup(kubernetes_secret.sa_secret.0.data, "token", "") : ""

  #
  # Kubernetes configuration file - Provider based format. May use helper tools
  #
  # NOTE - Formatting here is correct you must preserve the current indentation
  #
  kube_config_provider = <<-EOT
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${var.cluster_ca_cert}
    server: '${var.cluster_endpoint}'
  name: ${var.cluster_name}
contexts:
- context:
    cluster: ${var.cluster_name}
    user: ${var.cluster_name}
  name: ${var.cluster_name}
current-context: ${var.cluster_name}
kind: Config
preferences: {}
users:
- name: ${var.cluster_name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: gke-gcloud-auth-plugin
      installHint: Install gke-gcloud-auth-plugin for use with kubectl by following
        https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
      provideClusterInfo: true
      name: gcp
EOT

# TODO DELETE - REFERENCE
#- name: ${var.cluster_name}
#  user:
#    auth-provider:
#      config:
#        cmd-args: config config-helper --format=json
#        cmd-path: gcloud
#        access-token: '{.credential.access_token}'
#        expiry-key: '{.credential.token_expiry}'
#        token-key: '{.credential.access_token}'
#      name: gcp

  #
  # Kubernetes configuration file - Service Account based for portability
  #
  # NOTE - Formatting here is correct you must preserve the current indentation
  #
  kube_config_sa = <<-EOT
apiVersion: v1
kind: Config
clusters:
- name: ${var.cluster_name}
  cluster:
    server: ${var.cluster_endpoint}
    certificate-authority-data: >-
        ${var.cluster_ca_cert}
users:
- name: ${local.service_account_name}
  user:
    token: >-
        ${local.sa_secret_token}
contexts:
- name: ${var.cluster_name}    
  context:
    user: ${local.service_account_name}
    cluster: ${var.cluster_name}
    namespace: kube-system
current-context: ${var.cluster_name}
EOT

}
