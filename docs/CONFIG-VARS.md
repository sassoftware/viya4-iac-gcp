# List of valid configuration variables
Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

## Table of Contents

  - [Required Variables](#required-variables)
  - [Admin Access](#admin-access)
  - [Networking](#networking)
      - [Use Existing](#use-existing)
  - [General](#general)
  - [Nodepools](#nodepools)
    - [Default Nodepool](#default-nodepool)
    - [Additional Nodepools](#additional-nodepools)
  - [Storage](#storage)
  - [Google Container Registry (GCR)](#gcr)
  - [Postgres](#postgres)

Terraform input variables can be set in the following ways:
- Individually, with the [-var command line option](https://www.terraform.io/docs/configuration/variables.html#variables-on-the-command-line).
- In [variable definitions (.tfvars) files](https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files). We recommend this way for most variables.
- As [environment variables](https://www.terraform.io/docs/configuration/variables.html#environment-variables).

## Required Variables

| Name | Description | Type | Default | Notes |
| :--- | :--- | :--- | :--- | :--- |
| prefix | A prefix used in the name of all the GCP resources created by this script. | string | | The prefix string must start with a lowercase letter and contain only lowercase alphanumeric characters and dashes (-), but cannot end with a dash. |
| location | The GCP Region (for example "us-east1") or GCP Zone (for example "us-east1-b") to provision all resources in this script. | string | | See [this topic](user/Locations.md) on how to chose a region or a zone.  |
| project | The GCP Project to use | string | | |
| service_account_keyfile | Filename of the Service Account JSON file | string | Not required when running on a Google Cloud VM that is associated with the Service Account |
| ssh_public_key | Public ssh key for VMs | string | "~/.ssh/id_rsa.pub" | Value is required in order to access your VMs |

## GCP Authentication

The Terraform process manages GCP resources on your behalf. In order to do so, it needs to know the credentials for a GCP identity with the required permissions.

For more detailed information on what is needed see [Authenticating Terraform to access GCP](https://github.com/sassoftware/viya4-iac-gcp/blob/main/docs/user/TerraformGCPAuthentication.md)

## Admin Access

By default, the API of the GCP resources that are being created are only accessible through authenticated GCP clients (e.g. the Google Cloud Portal, the `gcloud` CLI, the Google Cloud Shell, etc.
To allow access for other administrative client applications (for example `kubectl`, `psql`, etc.), you need to open up the GCP firewall to allow access from your source IPs.
To do this, specify ranges of IP in [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing).
Contact your Network System Administrator to find the public CIDR range of your network.

You can use `default_public_access_cidrs` to set a default range for all created resources. To set different ranges for other resources, define the appropriate variable. Use and empty list `[]` to disallow access explicitly.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| private_cluster | Creates a cluster api endpoint with a private ip address instead of a public ip address | bool | | When "true", all "*_public_access_cidrs" options may not use public ip addresses. Access to the cluster is only allowed from restricted IP ranges. |
| default_public_access_cidrs | IP Ranges allowed to access all created cloud resources | list of strings | | Use to to set a default for all Resources |
| cluster_endpoint_public_access_cidrs | IP Ranges allowed to access the GKE cluster api | list of strings | | for client admin access to the cluster, e.g. with `kubectl` |
| vm_public_access_cidrs | IP Ranges allowed to access the VMs | list of strings | | opens port 22 for SSH access to the jump and/or nfs VM |
| postgres_public_access_cidrs | IP Ranges allowed to access the Google Cloud PostgreSQL Server | list of strings |||

## Networking
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| gke_subnet_cidr | Address space for the subnet for the GKE resources | string | "192.168.0.0/23" | This variable is ignored when `vpc_name` is set (aka bring your own vnet) |
| gke_pod_subnet_cidr | Secondary address space in the GKE subnet for Kubernetes Pods | string | "10.0.0.0/17" | This variable is ignored when `subnet_names` is set (aka bring your own subnets) |
| gke_service_subnet_cidr | Secondary address space in the GKE subnet for Kubernetes Services | string | "10.1.0.0/22" | This variable is ignored when `subnet_names` is set (aka bring your own subnets) |
| gke_control_plane_subnet_cidr |  Address space for the hosted master subnet | string | "10.2.0.0/28" | When providing your own subnets (by setting `subnet_names` make sure your subnets do not overlap this range  |
| misc_subnet_cidr | Address space for the the auxiliary resources (Jump VM and optionally NFS VM) subnet | string | "192.168.2.0/24" | This variable is ignored when `subnet_names` is set (aka bring your own subnet) |
| filestore_subnet_cidr | Address space for Google Filestore subnet | string | "192.168.3.0/29" | Needs to be at least a /29 range. Only used when `storage_type="ha"` |
| database_subnet_cidr | Address space for Google Cloud SQL Postgre subnet | string | "192.168.4.0/24" | Only used when `create_postgres=true` |



### Use Existing

If desired, you can deploy into an existing VPC, use existing subnets, and provide an existing Cloud NAT IP address. You will need a private subnet for the GKE nodes and a public subnet for the Jump VM and (if used) the NFS VM. The GKE subnet requires two secondary CIDR ranges for the Kubernetes Pods and Services (see https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips#cluster_sizing).

The existing subnets need to match the same region given in the `location` variable defined [here](#required-variables)

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| vpc_name | Name of pre-existing VPC | string | null | Only required if deploying into existing VPC |
| subnet_names | Existing subnets/secondary ranges mapped to desired usage | map(string) | null | Only required if deploying into existing subnets. See example below |
| nat_address_name | Name of existing IP address for existing Cloud NAT | string | null | If not given, a Cloud NAT and associated external IP will be created |

Example `subnet_names` variable:

```yaml
subnet_names = {
  ## Required subnet/range names
  "gke"                     = "name_of_my_gke_subnet"
  "gke_pods_range_name"     = "name_of_my_secondary_range_for_pods"
  "gke_services_range_name" = "name_of_my_secondary_range_for_services"
  "misc"                    = "name_of_my_misc_subnet"
}
```

Note: The subnets for filestore and database can not the pre-created. GCP creates the subnets as part of the services.

## General

The application of a Kubernetes version in GCP has some limitations when assigning channels and versions to the cluster. The doc outlining on these limitations can be found in the [Kubernetes Versions](user/KubernetesVersions.md) guide.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| kubernetes_version | The GKE cluster K8S version | string | "latest" | Valid values depend on the kubernetes_channel and version required, see https://cloud.google.com/kubernetes-engine/docs/release-notes |
| kubernetes_channel | The GKE cluster channel for auto-updates | string | "UNSPECIFIED" | Possible values: "STABLE", "REGULAR", "RAPID"; Set "UNSPECIFIED" for no auto-updates |
| enable_cluster_autoscaling | Enable cluster autoscaling | bool | false | |
| cluster_autoscaling_max_cpu_cores | MAX number of cores in the cluster | number | 500 | |
| cluster_autoscaling_max_memory_gb | MAX number of gb of memory in the cluster | number | 10000 | |
| create_static_kubeconfig | Allows the user to create a provider / service account based kube config file | bool | false | A value of `false` will default to using the cloud providers mechanism for generating the kubeconfig file. A value of `true` will create a static kubeconfig which utilizes a `Service Account` and `Cluster Role Binding` to provide credentials. |
| regional | Create a regional GKE control plane | bool | true | If false a zonal GKE control plane is created |
| create_jump_vm | Create bastion host | bool | true | |
| create_jump_public_ip | Add public ip to jump VM | bool | true | |
| jump_vm_admin | OS Admin User for the Jump VM | string | "jumpuser" | | 
| jump_rwx_filestore_path | File store mount point on Jump server | string | "/viya-share" | |
| tags | Map of common tags to be placed on all GCP resources created by this script | map | {} | |

## Nodepools

### Default Nodepool

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| default_nodepool_vm_type | Type of the default nodepool VMs | string | "e2-standard-8" | |
| default_nodepool_os_disk_size | Disk size for default nodepool VMs in GB | number | 128 ||
| default_nodepool_min_nodes | Minimum number of nodes for the default nodepool | number | 1 | |
| default_nodepool_max_nodes | Maximum number of nodes for the default nodepool | number | 5 | |
| default_nodepool_local_ssd_count | Number 375 GB local ssd disks to provision | number | 0 | You can pick up to 24 ssd drives per node |
| default_nodepool_taints | Taints for the default nodepool VMs | list of strings | [] | |
| default_nodepool_labels | Labels to add to the default nodepool VMs | map | {} | |

### Additional Nodepools

Additional node pools can be created separate from the default nodepool. This is done with the `node_pools` variable which is a map of objects. Each nodepool requires the following variables:

| Name | Description | Type | Notes |
| :--- | ---: | ---: | ---: |
| vm_type | Type of the nodepool VMs | string | |
| os_disk_size | Disk size for nodepool VMs in GB | number | |
| min_nodes | Minimum and initial number of nodes for the nodepool | number | Value must be >=0 and <= `max_nodes`. Setting min and max node counts the same disables autoscaling |
| max_nodes | Maximum number of nodes for the nodepool | number | Value must be >= `min_nodes`. Setting min and max node counts the same disables autoscaling |
| node_taints | Taints for the nodepool VMs | list of strings | |
| node_labels | Labels to add to the nodepool VMs | map | |
| local_ssd_count | Number of 375 GB local ssd disks to provision  | number | |
| accelerator_count | Number of GPU accelerators associated with this nodepool | number | |
| accelerator_type | Type of GPU accelerator associated with this nodepool | string | To list the available accelerators in your zone use the following command `gcloud compute accelerator-types list --filter="zone:( <your zone> )"` |

The default values for the `node_pools` variable are:

```yaml
cas = {
  "vm_type"      = "n1-highmem-16"
  "os_disk_size" = 200
  "min_nodes"    = 1
  "max_nodes"    = 5
  "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
  "node_labels" = {
    "workload.sas.com/class" = "cas"
  }
  "local_ssd_count"   = 0
  "accelerator_count" = 0
  "accelerator_type" = ""
},
compute = {
  "vm_type"      = "n1-highmem-16"
  "os_disk_size" = 200
  "min_nodes"    = 1
  "max_nodes"    = 5
  "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
  "node_labels" = {
    "workload.sas.com/class"        = "compute"
    "launcher.sas.com/prepullImage" = "sas-programming-environment"
  }
  "local_ssd_count"   = 0
  "accelerator_count" = 0
  "accelerator_type"  = ""
},
connect = {
  "vm_type"      = "n1-highmem-16"
  "os_disk_size" = 200
  "min_nodes"    = 1
  "max_nodes"    = 5
  "node_taints"  = ["workload.sas.com/class=connect:NoSchedule"]
  "node_labels" = {
    "workload.sas.com/class"        = "connect"
    "launcher.sas.com/prepullImage" = "sas-programming-environment"
  }
  "local_ssd_count"   = 0
  "accelerator_count" = 0
  "accelerator_type"  = ""
},
stateless = {
  "vm_type"      = "e2-standard-16"
  "os_disk_size" = 200
  "min_nodes"    = 1
  "max_nodes"    = 5
  "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
  "node_labels" = {
    "workload.sas.com/class" = "stateless"
  }
  "local_ssd_count"   = 0
  "accelerator_count" = 0
  "accelerator_type"  = ""
},
stateful = {
  "vm_type"      = "e2-standard-8"
  "os_disk_size" = 200
  "min_nodes"    = 1
  "max_nodes"    = 3
  "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
  "node_labels" = {
    "workload.sas.com/class" = "stateful"
  }
  "local_ssd_count"   = 0
  "accelerator_count" = 0
  "accelerator_type"  = ""
}
```

## Storage

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| storage_type | Type of Storage. Valid Values: "standard", "ha"  | string | "standard" |  "standard" creates NFS server VM, "ha" Google Filestore instance |

### For `storage_type=standard` only (NFS server VM)

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_nfs_public_ip | Add public ip to the NFS server VM | bool | false | The NFS server VM is only created when storage_type="standard" |
| nfs_vm_admin | OS Admin User for the NFS server VM | string | "nfsuser" | The NFS server VM is only created when storage_type="standard" |
| nfs_raid_disk_size | Size in Gb for each disk of the RAID5 cluster on the NFS server VM | number | 128 | The NFS server VM is only created when storage_type="standard" |

### For `storage_type=ha` only (Google Filestore)

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| filestore_tier | The service tier for the Google Filestore Instance | string | "BASIC_HDD" | Valid Values: "BASIC_HDD", "BASIC_SSD" (previously called "STANDARD" and "PREMIUM" respectively.)  |
| filestore_size_in_gb | Size in GB of Filesystem in the Google Filestore Instance | number | 1024 for BASIC_HDD, 2560 for BASIC_SDD | 2560 GB is the minimum size for the BASIC_SSD tier. The BASIC_HDD tier allows a minimum size of 1024 GB. |

## Google Container Registry (GCR)

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| enable_registry_access | Enable access from the GKE Cluster to the GCR for your Google Project | bool | true | adds the "Artifact Registry Reader" and
"Storage Object Viewer" Roles to the Service Account associated with the Node VMs. |


## Postgres Servers

When setting up ***external database servers***, you must provide information about those servers in the `postgres_servers` variable block. Each entry in the variable block represents a ***single database server***.

This code only configures database servers. No databases are created during the infrastructure setup.

The variable has the following format:

```terraform
postgres_servers = {
  default = {},
  ...
}
```

**NOTE**: The `default = {}` elements is always required when creating external databases. This is the systems default database server.

Each server element, like `foo = {}`, can contain none, some, or all of the parameters listed below:

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| machine_type| The machine type for the PostgreSQL server VMs" | string | "db-custom-8-30720" | Google Cloud Postgres supports only shared-core machine types such as db-f1-micro, and custom machine types such as db-custom-2-13312.
| storage_gb | Minimum storage allowed for the PostgreSQL server | number | 10 | |
| backups_enabled | Enables postgres backups | bool | true | |
| backups_start_time | Start time for postgres backups | string | "21:00" | |
| backups_location | TODO | string | null | |
| backups_point_in_time_recovery_enabled | Enable point-in-time recovery | bool | false | |
| backup_count | The number of automated backups to retain, from 1 to 365 | string | "7" | Take note this is a **COUNT** not number of days |
| administrator_login | The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created. | string | "pgadmin" | | |
| administrator_password | The Password associated with the administrator_login for the PostgreSQL Server | string | "my$up3rS3cretPassw0rd" |  |
| server_version | The version of the  PostgreSQL server instance | string | "11" | Supported values are 11 and 12 |
| ssl_enforcement_enabled | Enforce SSL on connection to the PostgreSQL database | bool | true | |
| availability_type | The availability type for the master instance. | string | "ZONAL" | This is only used to set up high availability for the PostgreSQL instance. Can be either `ZONAL` or `REGIONAL`. |
| database_flags | Database flags for the master instance. | list(object({})) |  | More details can be found [here](https://cloud.google.com/sql/docs/postgres/flags) |

Here is a sample of the `postgres_servers` variable with the `default` entry only overriding the `administrator_password` parameter and the `cps` entry overriding all of the parameters:

```terraform
postgres_servers = {
  default = {
    administrator_password       = "D0ntL00kTh1sWay"
  },
  another_server = {
    machine_type                           = "db-custom-8-30720"
    storage_gb                             = 10
    backups_enabled                        = true
    backups_start_time                     = "21:00"
    backups_location                       = null
    backups_point_in_time_recovery_enabled = false
    backup_count                           = 7 # Number of backups to retain, not in days
    administrator_login                    = "pgadmin"
    administrator_password                 = "my$up3rS3cretPassw0rd"
    server_version                         = "11"
    availability_type                      = "ZONAL"
    ssl_enforcement_enabled                = true
    database_flags                         = [{ name = "foo" value = "true"}, { name = "bar", value = "false"}]
  }
}
```
