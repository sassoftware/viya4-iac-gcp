# List of valid configuration variables
Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

## Table of Contents

* [Required Variables](#required-variables)
* [Admin Access](#admin-access)
* [General](#general)
* [Nodepools](#nodepools)
   + [Default Nodepool](#default-nodepool)
   + [CAS Nodepool](#cas-nodepool)
   + [Compute Nodepool](#compute-nodepool)
   + [Connect Nodepool](#connect-nodepool)
   + [Stateless Nodepool](#stateless-nodepool)
   + [Stateful Nodepool](#stateful-nodepool)
* [Storage](#storage)
* [Postgres](#postgres)

Terraform input variables can be set in the following ways:
- Individually, with the [-var command line option](https://www.terraform.io/docs/configuration/variables.html#variables-on-the-command-line).
- In [variable definitions (.tfvars) files](https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files). We recommend this way for most variables.
- As [environment variables](https://www.terraform.io/docs/configuration/variables.html#environment-variables). We recommend this way for the variables that set the [Azure authentication](#required-variables-for-azure-authentication).

## Required Variables

| Name | Description | Type | Notes |
| :--- | ---: | ---: | ---: | 
| prefix | A prefix used in the name of all the GCP resources created by this script. | string |  The prefix string must start with a lowercase letter and contain only alphanumeric characters and dashes (-), but cannot end with a dash. |
| location | The GCP Region (for example "us-east1") or GCP Zone (for example "us-east1-b") to provision all resources in this script.  | string | Choosing a Region will make this a multi-zonal cluster. If you are not sure which to choose, go with a ZONE instead of a region  |
| project | The GCP Project to use | string | |
| service_account_keyfile | Filename of the Service Account JSON file | string | |

## Admin Access

By default, the API of the GCP resources that are being created are only accessible through authenticated GCP clients (e.g. the Google Cloud Portal, the `gcloud` CLI, the Google Cloud Shell, etc.) 
To allow access for other administrative client applications (for example `kubectl`, `psql`, etc.), you need to open up the GCP firewall to allow access from your source IPs.
To do this, specify ranges of IP in [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing).
Contact your Network System Administrator to find the public CIDR range of your network.

You can use `default_public_access_cidrs` to set a default range for all created resources. To set different ranges for other resources, define the appropriate variable. Use and empty list `[]` to disallow access explicitly.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: | 
| default_public_access_cidrs | IP Ranges allowed to access all created cloud resources | list of strings | | Use to to set a default for all Resources |
| cluster_endpoint_public_access_cidrs | IP Ranges allowed to access the GKE cluster api | list of strings | | for client admin access to the cluster, e.g. with `kubectl` |
| vm_public_access_cidrs | IP Ranges allowed to access the VMs | list of strings | | opens port 22 for SSH access to the jump and/or nfs VM |
| postgres_access_cidrs | IP Ranges allowed to access the Google Cloud PostgreSQL Server | list of strings |||


## General 
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: | 
| kubernetes_version | The GKE cluster K8S version | string | "1.18.6-gke.4801" | Valid depend on the kubernetes_channel, see https://cloud.google.com/kubernetes-engine/docs/release-notes|
| kubernetes_channel | The GKE cluster channel | string | "RAPID" | Possible values: "STABLE", "REGULAR", "RAPID", "" |
| ssh_public_key | Public ssh key for VMs | string | | |
| create_jump_vm | Create bastion host | bool | true for storage_type == "standard", otherwise false| |
| create_jump_public_ip | Add public ip to jump VM | bool | true | |
| jump_vm_admin | OS Admin User for the Jump VM | string | "jumpuser" | | 
| tags | Map of common tags to be placed on all GCP resources created by this script | map | {} | |

## Nodepools
### Default Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| default_nodepool_vm_type | Type of the default nodepool VMs | string | "n1-standard-1" | |
| default_nodepool_node_count | Number of nodes in the default nodepool | number | 2 | The value must be between `default_nodepool_min_nodes` and `default_nodepool_max_nodes`|
| default_nodepool_max_nodes | Maximum number of nodes for the default nodepool | number | 5 | |
| default_nodepool_min_nodes | Minimum number of nodes for the default nodepool | number | 1 | |
| default_nodepool_os_disk_size | Disk size for default nodepool VMs in GB | number | 128 ||
| default_nodepool_local_ssd_count | Number 375 GB local ssd disks to provision | number | 0 | You can pick up to 24 ssd drives per node |
| default_nodepool_taints | Taints for the default nodepool VMs | list of strings |  | |
| default_nodepool_labels | Labels to add to the default nodepool VMs | map | | |

### CAS Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_cas_nodepool | Create CAS nodepool | bool | true | |
| cas_nodepool_vm_type | Type of the CAS nodepool VMs | string | "n1-highmem-16" | |
| cas_nodepool_node_count | Number of nodes in the CAS nodepool | number | 1 | The value must be between `cas_nodepool_min_nodes` and `cas_nodepool_max_nodes`|
| cas_nodepool_max_nodes | Maximum number of nodes for the CAS nodepool | number | 5 | |
| cas_nodepool_min_nodes | Minimum number of nodes for the CAS nodepool | number | 1 | |
| cas_nodepool_os_disk_size | Disk size for CAS nodepool VMs in GB | number | 200 ||
| cas_nodepool_local_ssd_count | Number 375 GB local ssd disks to provision | number | 0 | You can pick up to 24 ssd drives per node |
| cas_nodepool_taints | Taints for the CAS nodepool VMs | list of strings | ["workload.sas.com/class=cas:NoSchedule"] | |
| cas_nodepool_labels | Labels to add to the CAS nodepool VMs | map | {"workload.sas.com/class" = "cas"} | |
### Compute Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_compute_nodepool | Create Compute nodepool | bool | true | false | |
| compute_nodepool_vm_type | Type of the Compute nodepool VMs | string | "n1-highmem-16" | |
| compute_nodepool_node_count | Number of nodes in the Compute nodepool | number | 1 | The value must be between 'compute_nodepool_min_nodes` and `compute_nodepool_max_nodes`|
| compute_nodepool_max_nodes | Maximum number of nodes for the Compute nodepool | number | 5 | |
| compute_nodepool_min_nodes | Minimum number of nodes for the Compute nodepool | number | 1 | |
| compute_nodepool_os_disk_size | Disk size for Compute nodepool VMs in GB | number | 200 ||
| compute_nodepool_local_ssd_count | Number 375 GB local ssd disks to provision | number | 0 | You can pick up to 24 ssd drives per node |
| compute_nodepool_taints | Taints for the Compute nodepool VMs | list of strings | ["workload.sas.com/class=compute:NoSchedule"] | |
| compute_nodepool_labels | Labels to add to the Compute nodepool VMs | map | {"workload.sas.com/class" = "compute"  "launcher.sas.com/prepullImage" = "sas-programming-environment" }  | |

### Connect Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_connect_nodepool | Create Connect nodepool | bool | true | false | |
| connect_nodepool_vm_type | Type of the Connect nodepool VMs | string | "n1-highmem-16" | |
| connect_nodepool_node_count | Number of nodes in the Connect nodepool | number | 1 | The value must be between 'connect_nodepool_min_nodes` and `connect_nodepool_max_nodes`|
| connect_nodepool_max_nodes | Maximum number of nodes for the Connect nodepool | number | 5 | |
| connect_nodepool_min_nodes | Minimum number of nodes for the Connect nodepool | number | 1 | |
| connect_nodepool_os_disk_size | Disk size for Connect nodepool VMs in GB | number | 200 ||
| connect_nodepool_local_ssd_count | Number 375 GB local ssd disks to provision | number | 0 | You can pick up to 24 ssd drives per node |
| connect_nodepool_taints | Taints for the Connect nodepool VMs | list of strings | ["workload.sas.com/class=connect:NoSchedule"] | |
| connect_nodepool_labels | Labels to add to the Connect nodepool VMs | map | {"workload.sas.com/class" = "connect"  "launcher.sas.com/prepullImage" = "sas-programming-environment" } | |

### Stateless Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_stateless_nodepool | Create Stateless nodepool | bool | true | |
| stateless_nodepool_vm_type | Type of the Stateless nodepool VMs | string | "e2-standard-16" | |
| stateless_nodepool_node_count | Number of nodes in the Stateless nodepool | number | 1 | The value must be between 'stateless_nodepool_min_nodes` and `stateless_nodepool_max_nodes`|
| stateless_nodepool_max_nodes | Maximum number of nodes for the Stateless nodepool | number | 5 | |
| stateless_nodepool_min_nodes | Minimum number of nodes for the Stateless nodepool | number | 1 | |
| stateless_nodepool_os_disk_size | Disk size for Stateless nodepool VMs in GB | number | 200 ||
| stateless_nodepool_local_ssd_count | Number 375 GB local ssd disks to provision | number | 0 | You can pick up to 24 ssd drives per node |
| stateless_nodepool_taints | Taints for the Stateless nodepool VMs | list of strings | ["workload.sas.com/class=stateless:NoSchedule"] | |
| stateless_nodepool_labels | Labels to add to the Stateless nodepool VMs | map | {"workload.sas.com/class" = "stateless" } | |
### Stateful Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_stateful_nodepool | Create Stateful nodepool | bool | true | |
| stateful_nodepool_vm_type | Type of the Stateful nodepool VMs | string | "e2-standard-8" | |
| stateful_nodepool_node_count | Number of nodes in the Stateful nodepool | number | 1 | The value must be between 'stateful_nodepool_min_nodes` and `stateful_nodepool_max_nodes`|
| stateful_nodepool_max_nodes | Maximum number of nodes for the Stateful nodepool | number | 3 | |
| stateful_nodepool_min_nodes | Minimum number of nodes for the Stateful nodepool | number | 1 | |
| stateful_nodepool_os_disk_size | Disk size for Stateful nodepool VMs in GB | number | 200 ||
| stateful_nodepool_local_ssd_count | Number 375 GB local ssd disks to provision | number | 0 | You can pick up to 24 ssd drives per node |
| stateful_nodepool_taints | Taints for the Stateful nodepool VMs | list of strings | ["workload.sas.com/class=stateful:NoSchedule"] | |
| stateful_nodepool_labels | Labels to add to the Stateful nodepool VMs | map | {"workload.sas.com/class" = "stateful" }  | |

## Storage
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| storage_type | Type of Storage. Valid Values: "standard", "ha"  | string | "standard" |  "standard" creates NFS server VM, "ha" Google Filestore instance |
### For `storage_type=standard` only (NFS server VM):
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_nfs_public_ip | Add public ip to the NFS server VM | bool | false | The NFS server VM is only created when storage_type="standard" |
| nfs_vm_admin | OS Admin User for the NFS server VM | string | "nfsuser" | The NFS server VM is only created when storage_type="standard" |
| nfs_raid_disk_size | Size in Gb for each disk of the RAID5 cluster on the NFS server VM | number | 128 | The NFS server VM is only created when storage_type="standard" |

## Postgres
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_postgres | Create a PostgreSQL server instance | bool | false | |
| postgres_name | The name of the PostgreSQL Server | string | <computed > | Once used, a name cannot be reused for up to [one week](https://cloud.google.com/sql/docs/mysql/delete-instance) |
| postgres_machine_type| The machine type for the PostgreSQL server VMs" | string | "db-custom-8-30720" | Google Cloud Postgres supports only shared-core machine types such as db-f1-micro, and custom machine types such as db-custom-2-13312. 
| postgres_storage_gb | Minimum storage allowed for the PostgreSQL server | number | 10 | |
| postgres_administrator_login | The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created. | string | "pgadmin" | | |
| postgres_administrator_password | The Password associated with the postgres_administrator_login for the PostgreSQL Server | string | |  |
| postgres_server_version | The version of the  PostgreSQL server instance | string | "11" | Valid values are 9.6, 10, 11, and 12 |
| postgres_ssl_enforcement_enabled | Enforce SSL on connection to the PostgreSQL database | bool | false | |





