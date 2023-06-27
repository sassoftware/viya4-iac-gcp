# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

ARG TERRAFORM_VERSION=1.4.5
ARG GCP_CLI_VERSION=428.0.0

FROM hashicorp/terraform:$TERRAFORM_VERSION as terraform
FROM google/cloud-sdk:$GCP_CLI_VERSION-alpine
ARG KUBECTL_VERSION=1.25.8
ARG ENABLE_GKE_GCLOUD_AUTH_PLUGIN=True

WORKDIR /viya4-iac-gcp

COPY --from=terraform /bin/terraform /bin/terraform
COPY . .

RUN apk update \
  && apk add --no-cache jq \
  && curl -sLO https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl \
  && chmod 755 ./kubectl /viya4-iac-gcp/docker-entrypoint.sh \
  && mv ./kubectl /usr/local/bin/kubectl \
  && chmod g=u -R /etc/passwd /etc/group /viya4-iac-gcp \
  && git config --system --add safe.directory /viya4-iac-gcp \
  && terraform init \
  && gcloud components install gke-gcloud-auth-plugin alpha beta cloud_sql_proxy \
  && rm -rf /google-cloud-sdk/.install/.backup

ENV TF_VAR_iac_tooling=docker
ENV USE_GKE_GCLOUD_AUTH_PLUGIN=$ENABLE_GKE_GCLOUD_AUTH_PLUGIN
ENTRYPOINT ["/viya4-iac-gcp/docker-entrypoint.sh"]
VOLUME ["/workspace"]
