# Create service account secret
resource "kubernetes_secret" "sa_secret" {
  count = var.create_static_kubeconfig ? 1 : 0
  metadata {
    name      = local.service_account_secret_name
    namespace = var.namespace
    annotations = {
      "kubernetes.io/service-account.name" = local.service_account_name
    }
  }
  type = "kubernetes.io/service-account-token"
  #   depends_on = [kubernetes_service_account.kubernetes_sa]
}

# Create service account for use with the service account kube config
#
# NOTE: Starting K8s v1.24+ hashicorp/terraform-provider-kubernetes issues
#       the following warning message:
#
#       "Warning: 'default_secret_name' is no longer applicable for Kubernetes
#                 'v1.24.0' and above"
#
resource "kubernetes_service_account" "kubernetes_sa" {
  count = var.create_static_kubeconfig ? 1 : 0
  metadata {
    name      = local.service_account_name
    namespace = var.namespace
  }
}

# Cluster role binding  used with the service account based kube config
resource "kubernetes_cluster_role_binding" "kubernetes_crb" {
  count = var.create_static_kubeconfig ? 1 : 0
  metadata {
    name = local.cluster_role_binding_name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.service_account_name
    namespace = var.namespace
  }
}
