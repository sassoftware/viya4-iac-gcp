# !NOTE! - These are only a subset of variables.tf provided for sample.
# Customize this file to add any variables from 'variables.tf' that you want 
# to change their default values. 

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                                  = "<prefix-value>"
location                                = "<gcp-zone-or-region>" # e.g., "us-east1-b""
project                                 = "<gcp-project>"
service_account_keyfile                 = "<service-account-json-file>"
# ****************  REQUIRED VARIABLES  ****************

# Source address ranges to allow client admin access to the cloud resources
default_public_access_cidrs    = []  # e.g., ["123.45.6.89/32"]

# add labels to the created resources
tags                                    = { } # e.g., { "key1" = "value1", "key2" = "value2" }

# When a ssh key value is provided it will be used for all VMs or else a ssh key will be auto generated and available in outputs
ssh_public_key                  = "~/.ssh/id_rsa.pub"

# Azure Postgres config
create_postgres                  = true # set this to "false" when using internal Crunchy Postgres
postgres_ssl_enforcement_enabled = false
postgres_administrator_password  = "mySup3rS3cretPassw0rd"

# AKS config
kubernetes_version                   = "1.18.6-gke.4801"
kubernetes_channel                   = "RAPID"
default_nodepool_node_count          = 2
default_nodepool_vm_type             = "n1-standard-1"

# AKS Node Pools config
create_cas_nodepool       = true
cas_nodepool_node_count   = 1
cas_nodepool_min_nodes    = 1
cas_nodepool_vm_type      = "n1-highmem-16"

create_compute_nodepool       = true
compute_nodepool_node_count   = 1
compute_nodepool_min_nodes    = 1
compute_nodepool_vm_type      = "n1-highmem-16"

create_connect_nodepool       = true
connect_nodepool_node_count   = 1
connect_nodepool_min_nodes    = 1
connect_nodepool_vm_type      = "n1-highmem-16"

create_stateless_nodepool       = true
stateless_nodepool_node_count   = 2
stateless_nodepool_min_nodes    = 2
stateless_nodepool_vm_type      = "e2-standard-16"

create_stateful_nodepool       = true
stateful_nodepool_node_count   = 3
stateful_nodepool_min_nodes    = 3
stateful_nodepool_vm_type      = "e2-standard-8"

# Jump Box
create_jump_public_ip          = true
jump_vm_admin                  = "jumpuser"

# Storage for SAS Viya CAS/Compute
storage_type = "standard"
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip  = false
nfs_vm_admin          = "nfsuser"
nfs_raid_disk_size    = 128
