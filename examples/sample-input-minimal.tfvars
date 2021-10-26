# !NOTE! - These are only a subset of CONFIG-VARS.md provided for sample.
# Customize this file to add any variables from 'CONFIG-VARS.md' that you want 
# to change their default values.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                  = "<prefix-value>"
location                = "<gcp-zone-or-region>" # e.g., "us-east1-b"
project                 = "<gcp-project>"
service_account_keyfile = "<service-account-json-file>"
#
# ****************  REQUIRED VARIABLES  ****************

# Source address ranges to allow client admin access to the cloud resources
default_public_access_cidrs = [] # e.g., ["123.45.6.89/32"]

# add labels to the created resources
tags = {} # e.g., { "key1" = "value1", "key2" = "value2" }

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
# postgres_servers = {
#   default = {},
# }

# GKE config
default_nodepool_min_nodes = 1
default_nodepool_vm_type   = "n2-standard-2"

## Cluster Node Pools config - mimimal
cluster_node_pool_mode   = "minimal"
node_pools = {
  cas = {
    "vm_type"              = "n2-highmem-4"
    "os_disk_size"         = 200
    "min_nodes"            = 0
    "max_nodes"            = 5
    "node_taints"          = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "local_ssd_count"      = 0
    "accelerator_count"    = 0
    "accelerator_type"     = ""
  },
  generic = {
    "vm_type"              = "n2-standard-8"
    "os_disk_size"         = 200
    "min_nodes"            = 0
    "max_nodes"            = 5
    "node_taints"          = []
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "local_ssd_count"      = 0
    "accelerator_count"    = 0
    "accelerator_type"     = ""
  }
}

# Jump Box
create_jump_public_ip = true
jump_vm_admin         = "jumpuser"
jump_vm_type          = "e2-medium"

# Storage for SAS Viya CAS/Compute
storage_type = "standard"
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip = false
nfs_vm_admin         = "nfsuser"
nfs_vm_type          = "n2-standard-4"
nfs_raid_disk_size   = 128
