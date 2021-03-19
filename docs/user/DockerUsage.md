# Using Docker Container

## Prereqs

- Docker [installed on your workstation](../../README.md#docker).

- Prepare your `terraform.tfvars` file, as described in [Customize Input Values](../../README.md#customize-input-values).

## Preparation

### Docker image

Run the following command to create the `viya4-iac-gcp` Docker image using the provided [Dockerfile](../../Dockerfile)

```bash
docker build -t viya4-iac-gcp .
```

The Docker image `viya4-iac-gcp` will contain Terraform and 'kubectl' executables. The Docker entrypoint for the image is `terraform` that will be run with sub-commands in the subsequent steps.

### Service Account Keyfile for GCP Authentication 

Prepare a file with GCP authentication info, as described in [Authenticating Terraform to access GCP](./TerraformGCPAuthentication.md) and store it outside of this repo in a secuire file, for example `$HOME/.viya4-tf-gcp-service-account.json`.

### Docker Volume Mounts

Add volume mounts to the `docker run` command for all files and directories that must be accessible from inside the container.
- `--volume=$HOME/.viya4-tf-gcp-service-account.json:/.viya4-tf-gcp-service-account.json` Service Account Key file for GCP authentication
- `--volume=$HOME/.ssh:/.ssh` for [`ssh_public_key`](../CONFIG-VARS.md#required-variables) variable in the `terraform.tfvars` file
- `--volume=$(pwd):/workspace` for local directory where `terraform.tfvars` file resides and where `terraform.tfstate` file will be written. To grant Docker, permission to write to the local directory use [`--user` option](https://docs.docker.com/engine/reference/run/#user)

The most common filre references are the values of the [`service_account_keyfile`](./CONFIG-VARS.md#required-variables) and [`ssh_public_key`](./CONFIG-VARS.md#required-variables) variables in the `terraform.tfvars` file.

**Note** that local references to `$HOME` (or "`~`") need to map to the root directory `/` in the container.

### Variable Definitions (.tfvars) File

Prepare your `terraform.tfvars` file, as described in [Customize Input Values](../../README.md#customize-input-values).

## Running Terraform Commands

### Preview Cloud Resources (optional)

To preview the cloud resources before creating, run the Docker image `viya4-iac-gcp` with the `plan` command

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --volume $HOME/.viya4-tf-gcp-service-account.json:/.viya4-tf-gcp-service-account.json \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-gcp \
  plan -var-file=/workspace/terraform.tfvars \
       -state=/workspace/terraform.tfstate  
```

### Create Cloud Resources

To create the cloud resources, run the Docker image `viya4-iac-gcp` with the `apply` command and `-auto-approve` option

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --volume $HOME/.viya4-tf-gcp-service-account.json:/.viya4-tf-gcp-service-account.json \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-gcp \
  apply -auto-approve \
        -var-file=/workspace/terraform.tfvars \
        -state=/workspace/terraform.tfstate 
```

This command can take a few minutes to complete. Once complete, Terraform output values are written to the console. The 'KUBECONFIG' file for the cluster is written to `[prefix]-gke-kubeconfig.conf` in the current directory `$(pwd)`.

### Display Outputs

Once the cloud resources have been created with `apply` command, to display Terraform output values, run the Docker image `viya4-iac-gcp` with `output` command

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --volume $HOME/.viya4-tf-gcp-service-account.json:/.viya4-tf-gcp-service-account.json \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-gcp \
  output -state=/workspace/terraform.tfstate 
```

### Modify Cloud Resources

After provisioning the infrastructure if further changes were to be made then update corresponding variables with desired values in `terraform.tfvars` and run the Docker image `viya4-iac-gcp` with the `apply` command and `-auto-approve` option again

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --volume $HOME/.viya4-tf-gcp-service-account.json:/.viya4-tf-gcp-service-account.json \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-gcp \
  apply -auto-approve \
        -var-file=/workspace/terraform.tfvars \
        -state=/workspace/terraform.tfstate 
```

### Tear Down Cloud Resources 

To destroy all the cloud resources created with the previous commands, run the Docker image `viya4-iac-gcp` with the `destroy` command and `-auto-approve` option

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --volume $HOME/.viya4-tf-gcp-service-account.json:/.viya4-tf-gcp-service-account.json \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-gcp \
  destroy -auto-approve \
          -var-file=/workspace/terraform.tfvars \
          -state=/workspace/terraform.tfstate
```
**NOTE:** The 'destroy' action is irreversible.

## Interacting with Kubernetes cluster

[Creating the cloud resources](#create-cloud-resources) writes the `kube_config` output value to a file `./[prefix]-gke-kubeconfig.conf`. When the Kubernetes cluster is ready, use `--entrypoint kubectl` to interact with the cluster.

**Note** this requires [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) value to be set to your local ip or CIDR range.

### `kubectl` Example:

```bash
docker run --rm \
  --env=KUBECONFIG=/workspace/<your prefix>-gke-kubeconfig.conf \
  --volume=$(pwd):/workspace \
  --entrypoint kubectl \
  viya4-iac-gcp get nodes 

```
