# Using Docker Container

## Prereqs

- Make sure you have Docker [installed on your workstation](../../README.md#docker).
- Prepare a file with authentication info, as described in [Authenticating Terraform to access GCP](./TerraformGCPAuthentication.md)
- Prepare your `terraform.tfvars` file, as described in [Customize Input Values](../../README.md#customize-input-values).


## Build the docker image

Run the following command to create the `viya4-iac-gcp` docker image that will be used in subsequent steps:

```bash
docker build -t viya4-iac-gcp .
```

NOTE: The Dockerfile for the container can be found [here](../../Dockerfile).


##### Preparation

Add volume mounts to the `docker run` command for all files and directories that must be accessible from inside the container.

The most common filre references are the values of the [`service_account_keyfile`](./CONFIG-VARS.md#required-variables) and [`ssh_public_key`](./CONFIG-VARS.md#required-variables) variables in the `terraform.tfvars` file.

Note that local references to `$HOME` (or "`~`") need to map to the root directory `/` in the container.

## Preview Cloud Resources (optional)

To preview which resources will be created, run

```bash
docker run --rm --userr "$(id -u):$(id -g)" \
  --volume $HOME/.viya4-tf-gcp-service-account.json:/.viya4-tf-gcp-service-account.json \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-gcp \
  plan -var-file=/workspace/terraform.tfvars \
       -state=/workspace/terraform.tfstate  
```

## Create Cloud Resources

To create the cloud resources, run

```bash
docker run --rm --user "$(id -u):$(id -g)"  --group-add root \
  --volume $HOME/.viya4-tf-gcp-service-account.json:/.viya4-tf-gcp-service-account.json \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-gcp \
  apply -auto-approve \
        -var-file=/workspace/terraform.tfvars \
        -state=/workspace/terraform.tfstate 
```
This command can take a few minutes to complete. Once complete, output values are written to the console.

The kubeconfig file for the cluster is being written to `[prefix]-gke-kubeconfig.conf` in the current directory `$(pwd)`.

## Display Outputs

The output values can be displayed anytime again by running

```bash
docker run --rm --user "$(id -u):$(id -g)" --group-add root \
  --volume $(pwd):/workspace \
  viya4-iac-gcp \
  output -state=/workspace/terraform.tfstate 
 
```

## Modify Cloud Resources

After provisioning the infrastructure if further changes were to be made then add the variable and desired value to `terraform.tfvars` and run again:

```bash
docker run --rm --user "$(id -u):$(id -g)" --group-add root \
  --volume $HOME/.viya4-tf-gcp-service-account.json:/.viya4-tf-gcp-service-account.json \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-gcp \
  apply -auto-approve \
        -var-file=/workspace/terraform.tfvars \
        -state=/workspace/terraform.tfstate 
```


## Tear Down Resources 

To destroy the cloud resources created with the previous commands, run

```bash
docker run --rm --user "$(id -u):$(id -g)" --group-add root \
  --volume $HOME/.viya4-tf-gcp-service-account.json:/.viya4-tf-gcp-service-account.json \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-gcp \
  destroy -auto-approve \
          -var-file=/workspace/terraform.tfvars \
          -state=/workspace/terraform.tfstate
```
NOTE: The "destroy" action is irreversible.

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
