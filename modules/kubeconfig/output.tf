output "kube_config" {
  value = var.tf_cloud_integration_enabled ? null : local_file.kubeconfig.*.content
}
