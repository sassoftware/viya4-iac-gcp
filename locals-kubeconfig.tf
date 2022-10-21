locals {
  kube_config_provider = <<-EOT
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${module.gke.ca_certificate}
    server: 'https://${module.gke.endpoint}'
name: ${module.gke.name}
contexts:
- context:
    cluster: ${module.gke.name}
    user: ${module.gke.name}
name: ${module.gke.name}
current-context: ${module.gke.name}
kind: Config
preferences: {}
users:
- name: ${module.gke.name}
user:
    auth-provider:
    config:
        cmd-args: config config-helper --format=json
        cmd-path: gcloud
        access-token: '{.credential.access_token}'
        expiry-key: '{.credential.token_expiry}'
        token-key: '{.credential.access_token}'
    name: gcp
EOT

  kube_config_sa = <<-EOT
apiVersion: v1
kind: Config
clusters:
- name: ${module.gke.name}
    cluster:
    server: 'https://${module.gke.endpoint}'
    certificate-authority-data: >-
        ${module.gke.ca_certificate}
users:
- name: ${local.service_account_name}
    user:
    token: >-
        {token}
contexts:
- name: ${module.gke.name}    
    context:
    user: ${local.service_account_name}
    cluster: ${module.gke.name}
    namespace: kube-system
current-context: ${module.gke.name}
EOT

}
