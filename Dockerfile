FROM hashicorp/terraform:0.13.3 as terraform

FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine

RUN apk --update --no-cache add git openssh

WORKDIR /viya4-iac-gcp

COPY --from=terraform /bin/terraform /bin/terraform

COPY . .

RUN terraform init /viya4-iac-gcp