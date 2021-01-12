# SAS Viya 4 IaC for Google GCP

## Overview

This project contains Terraform scripts to provision Google GCP infrastructure resources required to deploy SAS Viya 4 products. Here is a list of resources this project can create :

  - VPC Network and Network Firewalls
  - Managed Google Kubernetes Engine (GKE) cluster
  - System and User GKE Node pools with required Labels and Taints
  - Infrastructure to deploy SAS Viya CAS in SMP or MPP mode
  - Shared Storage options for SAS Viya -  Google Filestore (ha) or NFS Server (standard)
  - Google Cloud SQL for PostgreSQL instance, optional

## Prerequisites

Operational knowledge of 
- [Terraform](https://www.terraform.io/intro/index.html)
- [Google Cloud Platform](https://https://cloud.google.com/)
- [Kubernetes](https://kubernetes.io/docs/concepts/).

Google Cloud Resources:

- Access to a [**Google Cloud "Project"**](https://cloud.google.com/resource-manager/docs/creating-managing-projects) with [these API Services](docs/user/APIServices.md) enabled. 
- A [Google CLoud Service Account](./docs/user/TerraformGCPAuthentication.md).
- [GCLOUD CLI](https://cloud.google.com/sdk/gcloud) - useful as an alternative to the Google CLoud Platform Portal

This tool supports running both from terraform installed on your local machine or via a docker container. The Dockerfile for the container can be found [here](Dockerfile)

### Terraform

- [Terraform](https://www.terraform.io/downloads.html) - v0.13.4
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl) - v1.18.8
- [jq](https://stedolan.github.io/jq/) - v1.6
### Docker

- [Docker](https://docs.docker.com/get-docker/)

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

See [Authenticating Terraform to access GCP](./docs/user/TerraformGCPAuthentication.md) for details.

### Building the docker image

Run the following command to create your `viya4-iac-gcp` local docker image

```bash
docker build -t viya4-iac-gcp .
```

### Customize Input Values

Create a file named `terraform.tfvars` to customize any input variable value. For starters, you can copy one of the provided example variable definition files in `./examples` folder. For more details on the variables declared in [variables.tf](variables.tf) refer to [CONFIG-VARS.md](docs/CONFIG-VARS.md).

When using a variable definition file other than `terraform.tfvars`, see [Advanced Terraform Usage](docs/user/AdvancedTerraformUsage.md) for additional command options.

### Running 

#### Terraform

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

To destroy the kubernetes cluster and all related resources, run

```bash
terraform destroy
```
NOTE: The "destroy" action is destructive and irreversible.

#### Docker

##### Preparation

When using the Docker container you need to make sure that all file references in your `terraform.tfvars` file are accessible inside the container. The easiest way to achieve this is to make sure that the files specified in the following variables are stored within your project directory:

| Name | Description | 
| :--- | :--- |   
| service_account_keyfile | Filename of the Service Account JSON file |
| ssh_public_key | Filename of the public ssh key to use for all VMs | 

Then copy `terraform.tfvars` file to `terraform.docker.tfvars` and modify the paths to those variables to use `/workspace/<relative filename in the current project directory>`, because your current project directory will be mounted as `/workspace` within the container.

##### Sample Actions

To preview the resources that the Terraform script will create, optionally run

```bash
docker run --rm -u "$UID:$GID" \
  -v $(pwd):/workspace \
  viya4-iac-gcp \
  plan -var-file=/workspace/terraform.docker.tfvars \
       -state /workspace/terraform.tfstate  
```

When satisfied with the plan and ready to create cloud resources, run

```bash
docker run --rm -u "$UID:$GID" \
  -v $(pwd):/workspace viya4-iac-gcp \
  apply -auto-approve \
        -var-file=/workspace/terraform.docker.tfvars \
        -state /workspace/terraform.tfstate 
```
`terraform apply` can take a few minutes to complete. Once complete, output values are written to the console.

The output values can be displayed anytime by again running

```bash
docker run --rm -u "$UID:$GID" \
  -v $(pwd):/workspace viya4-iac-gcp \
  output -state /workspace/terraform.tfstate 
 
```

To destroy the kubernetes cluster and all related resources, run

```bash
docker run --rm -u "$UID:$GID" \
  -v $(pwd):/workspace viya4-iac-gcp \
  destroy -auto-approve \
          -var-file=/workspace/terraform.docker.tfvars \
          -state /workspace/terraform.tfstate
```
NOTE: The "destroy" action is destructive and irreversible.


### Modifying Cloud Resources

After provisioning the infrastructure if changes were to be made to inputs e.g., change number of nodes in a node pool or set create_postgres to true/false, then add the variable to terraform.tfvars and changes the value and run either `terraform apply` or the equivalent `docker run ... apply` command.
### Interacting with Kubernetes cluster

Terraform script writes `kube_config` output value to a file `./[prefix]-gke-kubeconfig.conf`. Now that you have your Kubernetes cluster up and running, here iis how to connect to the cluster:

#### Terraform 

```bash
export KUBECONFIG=./<your prefix>-gke-kubeconfig.conf
kubectl get nodes
```

#### Docker

```bash
docker run --rm \
  -e KUBECONFIG=/workspace/<your prefix>-gcp-kubeconfig.conf \
  -v $(pwd):/workspace \
  --entrypoint kubectl \
  viya4-iac-gcp get nodes 

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
