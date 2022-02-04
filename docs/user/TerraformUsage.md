# Using the Terraform CLI

## Prereqs

When using the Terraform CLI, make sure you have all the necessary tools [installed on your workstation](../../README.md#terraform).

## Preparation

### Set GCP Authentication

Prepare a file with authentication info, as described in [Authenticating Terraform to access GCP](./TerraformGCPAuthentication.md).

### Prepare Variable Definitions (.tfvars) File

Prepare your `terraform.tfvars` file, as described in [Customize Input Values](../../README.md#customize-input-values).

## Running Terraform Commands

### Initialize Terraform Environment

Initialize the Terraform environment for this project by running

```bash
terraform init
```

This creates a `.terraform` directory locally and initializes Terraform plugins and modules used in this project.

**Note:** `terraform init` only needs to be run once unless new Terraform plugins or modules were added.

### Preview Cloud Resources (optional)

To preview the resources that the Terraform script will create, run

```bash
terraform plan
```

### Create Cloud Resources

When satisfied with the plan and ready to create cloud resources, run

```bash
terraform apply -auto-approve
```

This command can take a few minutes to complete. Once complete, Terraform output values are written to the console. 

The kubeconfig file for the cluster is being written to `[prefix]-gke-kubeconfig.conf` in the current directory `$(pwd)`.

### Display Outputs

Once the cloud resources have been created with `apply` command, to display Terraform output values, run 

```bash
terraform output
```

### Modify Cloud Resources

After provisioning the infrastructure, if further changes were to be made then add the variable and desired value to `terraform.tfvars` and run `terrafom apply` again.

### Tear Down Cloud Resources

To destroy the kubernetes cluster and all related resources, run

```bash
terraform destroy
```
NOTE: The "destroy" action is irreversible.

## Interacting with the Kubernetes cluster

[Creating the cloud resources](#create-cloud-resources) writes the `kube_config` output value to a file `./[prefix]-gke-kubeconfig.conf`. When the Kubernetes cluster is ready, use `kubectl` to interact with the cluster.

**Note** this requires [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) value to be set to your local ip or CIDR range.

### Example Using `kubectl` 

```bash
export KUBECONFIG=$(pwd)/<your prefix>-aks-kubeconfig.conf
kubectl get nodes
```
