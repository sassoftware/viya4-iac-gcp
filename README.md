# SAS Viya 4 IaC for Google GCP

## Overview

This project contains Terraform scripts to provision Google GCP infrastructure resources required to deploy SAS Viya 4 products. Here is a list of resources this project can create :

  - VPC Network and Network Firewalls
  - Managed Google Kubernetes Engine (GKE) cluster
  - System and User GKE Node pools with required Labels and Taints
  - Infrastructure to deploy SAS Viya CAS in SMP or MPP mode
  - Shared Storage options for SAS Viya -  Google Filestore (ha) or NFS Server (standard)
  - Google Cloud PostgreSQL instance, optional

## Prerequisites

Operational knowledge of [Terraform](https://www.terraform.io/intro/index.html), [Google Cloud Platform](https://https://cloud.google.com/), and [Kubernetes](https://kubernetes.io/docs/concepts/).
This tool supports running both from terraform installed on your local machine or via a docker container. The Dockerfile for the container can be found [here](Dockerfile)

### Required

#### Terraform

- [Terraform](https://www.terraform.io/downloads.html) - v0.13.3
- Access to an **Google Cloud "Project"** and a **Google CLoud Service Account** 

#### Docker

- [Docker](https://docs.docker.com/get-docker/)
- Access to an **Google Cloud "Project"** and a **Google CLoud Service Account** 

### Optional

- [GCLOUD CLI](https://cloud.google.com/sdk/gcloud) - comes in handy as an alternative to the Google CLoud Platform Portal

## Getting Started

Run these commands in a Terminal session

### Clone this project

```bash
# clone this repo
git clone https://github.com/sassoftware/viya4-iac-gcp

# move to directory
cd viya4-iac-gcp
```

### Authenticating Terraform to access GCP

See [Authenticating Terraform to access TCP](./docs/user/TerraformGCPAuthentication.md) for details.

### Customize Input Values

Create a file named `terraform.tfvars` to customize any input variable value. For starters, you can copy one of the provided example variable definition files in `./examples` folder. For more details on the variables declared in [variables.tf](variables.tf) refer to [CONFIG-VARS.md](docs/CONFIG-VARS.md).

When using a variable definition file other than `terraform.tfvars`, see [Advanced Terraform Usage](docs/user/AdvancedTerraformUsage.md) for additional command options.

### Running Terraform Commands

Initialize the Terraform environment for this project by running 

```bash
terraform init
```

This creates a `.terraform` directory locally that contains Terraform plugins/modules used in this project.

**Note:** `terraform init` only needs to be run once unless new Terraform plugins/modules were added.

To preview the resources that the Terraform script will create, optionally run

```bash
terraform plan
```

When satisfied with the plan and ready to create cloud resources, run

```bash
terraform apply
```

`terraform apply` can take a few minutes to complete. Once complete, output values are written to the console. These output values can be displayed anytime by again running

```bash
terraform output
```

### Modifying Cloud Resources

After provisioning the infrastructure if changes were to be made to inputs e.g., change number of nodes in a node pool or set create_postgres to true/false, then add the variable to terraform.tfvars and changes the value and run `terrafom apply`.

### Interacting with Kubernetes cluster

Terraform script writes `kube_config` output value to a file `./[prefix]-gke-kubeconfig.conf`. Now that you have your Kubernetes cluster up and running, here's how to connect to the cluster

```bash
export KUBECONFIG=./[prefix]-gke-kubeconfig.conf
kubectl get nodes
```

### Examples

We include several samples - `sample-input*.tfvars` in this repo to get started. Evaluate the sample files, then review the [CONFIG-VARS.md](docs/CONFIG-VARS.md) to see what other variables can be used.

### Troubleshooting

See [troubleshooting](./docs/Troubleshooting.md) page.

## Contributing

> We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project. 

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

### GCP

- Google Cloud CLI - https://cloud.google.com/sdk/gcloud
- Terraform on GCP - https://cloud.google.com/docs/terraform
- Terraform and GCP Service Accounts - https://medium.com/@gmusumeci/how-to-create-a-service-account-for-terraform-in-gcp-google-cloud-platform-f75a0cf918d1
- GKE intro - https://cloud.google.com/kubernetes-engine

### Terraform 

- Google Provider - https://www.terraform.io/docs/providers/google/index.html
- Google GKE - https://www.terraform.io/docs/providers/google/r/container_cluster.html
