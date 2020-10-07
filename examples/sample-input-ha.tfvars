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

# Azure Postgres config
create_postgres                  = true # set this to "false" when using internal Crunchy Postgres
postgres_ssl_enforcement_enabled = false
postgres_administrator_password  = "mySup3rS3cretPassw0rd"

# GKE config
kubernetes_version                   = "1.18.6-gke.4801"
kubernetes_channel                   = "RAPID"
default_nodepool_node_count          = 2
default_nodepool_vm_type             = "n1-standard-1"

# AKS Node Pools config
create_cas_nodepool       = true
cas_nodepool_node_count   = 2
cas_nodepool_min_nodes    = 2
cas_nodepool_vm_type      = "n1-highmem-16"

create_compute_nodepool       = true
compute_nodepool_node_count   = 2
compute_nodepool_min_nodes    = 2
compute_nodepool_vm_type      = "n1-highmem-16"

create_connect_nodepool       = true
connect_nodepool_node_count   = 1
connect_nodepool_min_nodes    = 1
connect_nodepool_vm_type      = "n1-highmem-16"

create_stateless_nodepool       = true
stateless_nodepool_node_count   = 3
stateless_nodepool_min_nodes    = 3
stateless_nodepool_vm_type      = "e2-standard-16"

create_stateful_nodepool       = true
stateful_nodepool_node_count   = 3
stateful_nodepool_min_nodes    = 3
stateful_nodepool_vm_type      = "e2-standard-8"

# Jump Box
create_jump_public_ip          = true
jump_vm_admin                  = "jumpuser"

# Storage for Viya Compute Services
# Supported storage_type values
#    "standard" - Custom managed NFS Server VM and disks
#    "ha"       - Google Filestore  
storage_type = "ha"
