ARG TERRAFORM_VERSION=1.0.0
ARG GCP_CLI_VERSION=342.0.0
FROM hashicorp/terraform:$TERRAFORM_VERSION as terraform

FROM google/cloud-sdk:$GCP_CLI_VERSION
ARG KUBECTL_VERSION=1.19.9

WORKDIR /viya4-iac-gcp

COPY --from=terraform /bin/terraform /bin/terraform
COPY . .

RUN apt-get install -y jq \
  && curl -sLO https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl \
  && chmod 755 ./kubectl /viya4-iac-gcp/docker-entrypoint.sh \
  && mv ./kubectl /usr/local/bin/kubectl \
  && chmod g=u -R /etc/passwd /etc/group /viya4-iac-gcp \
  && chdir /viya4-iac-gcp ; terraform init

ENV TF_VAR_iac_tooling=docker
ENTRYPOINT ["/viya4-iac-gcp/docker-entrypoint.sh"]
VOLUME ["/workspace"]
