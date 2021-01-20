# Using the Terraform CLI

## Prereqs

- Make sure you have all the necessary tools [installed on your workstation](../../README.md#terraform.
- Prepare a file with authentication info, as described in [Authenticating Terraform to access GCP](./TerraformGCPAuthentication.md)
- Prepare your `terraform.tfvars` file, as described in [Customize Input Values](../../README.md#customize-input-values).


## Initialize Terraform 

Initialize the Terraform environment for this project by running

```bash
terraform init
```

This creates a `.terraform` directory locally and initializes Terraform plugins and modules used in this project.

**Note:** `terraform init` only needs to be run once unless new Terraform plugins or modules were added.

## Preview Cloud Resources (optional)

To preview the resources that the Terraform script will create, run

```bash
terraform plan
```

## Create CLoud Resources

When satisfied with the plan and ready to create cloud resources, run

```bash
terraform apply
```

This command can take a few minutes to complete. Once complete, Terraform output values are written to the console. 

## View Outputs

The output values can be displayed later at any time again by running

```bash
terraform output
```

## Modify Cloud Resources

After provisioning the infrastructure, if further changes were to be made then add the variable and desired value to `terraform.tfvars` and run `terrafom apply` again.

## Tear down Resources

To destroy the kubernetes cluster and all related resources, run

```bash
terraform destroy
```
NOTE: The "destroy" action is irreversible.

## Interacting with the Kubernetes cluster

Terraform script writes the `kube_config` output value to a file `./[prefix]-gke-kubeconfig.conf`. When theKubernetes cluster is ready, use `kubectl` to interact with the cluster.

**Note** this requires [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) value to be set to your local ip or CIDR range.

### `kubectl` Example

```bash
export KUBECONFIG=./<your prefix>-gke-kubeconfig.conf
kubectl get nodes
```
