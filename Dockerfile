ARG TERRAFORM_VERSION=0.13.4
ARG GCP_CLI_VERSION=319.0.0

FROM hashicorp/terraform:$TERRAFORM_VERSION as terraform
FROM google/cloud-sdk:$GCP_CLI_VERSION
ARG KUBECTL_VERSION=1.18.8

RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl \
  && chmod 755 ./kubectl \
  && mv ./kubectl /usr/local/bin/kubectl
COPY --from=terraform /bin/terraform /bin/terraform

WORKDIR /viya4-iac-gcp

COPY . .

RUN terraform init /viya4-iac-gcp

ENV TF_VAR_iac_tooling=docker
ENTRYPOINT [ "/bin/terraform" ]
