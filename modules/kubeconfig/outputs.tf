output "kube_config" {
  value = var.create_static_kubeconfig ? local.kube_config_sa : local.kube_config_provider
}
