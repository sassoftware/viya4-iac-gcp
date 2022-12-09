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

# ****************  RECOMMENDED VARIABLES  ****************
default_public_access_cidrs = [] # e.g., ["123.45.6.89/32"]
ssh_public_key              = "~/.ssh/id_rsa.pub"
# ****************  RECOMMENDED VARIABLES  ****************

# Bring your own existing resources
vpc_name        = "name-of-existing-vpc"
subnet_names    = { 
  gke                     = "<name-of-existing-subnetfor-gke>"
  gke_pods_range_name     = "<name-of-existing-secondary-ip-range-for-pods-in-gke-subnet>"
  gke_services_range_name = "<name-of-existing-secondary-ip-range-for-services-in-gke-subnet>"
  misc                    = "<name-of-existing-subnet-for-additional-vms>"
}
nat_address_name = "<name-of-existing-nat-ip-address>"

# add labels to the created resources
tags = {} # e.g., { "key1" = "value1", "key2" = "value2" }

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
postgres_servers = {
  default = {},
}

# GKE config
kubernetes_version = "1.23.14-gke.401"
default_nodepool_min_nodes = 2
default_nodepool_vm_type    = "e2-standard-8"

# Node Pools config
node_pools = {
  cas = {
    "vm_type"      = "n1-highmem-16"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 1
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "local_ssd_count"   = 0
    "accelerator_count" = 0
    "accelerator_type"  = ""
  },
  compute = {
    "vm_type"      = "n1-highmem-16"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 1
    "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
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
    "max_nodes"    = 2
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
}

# Jump Box
create_jump_public_ip = true
jump_vm_admin         = "jumpuser"

# Storage for SAS Viya CAS/Compute
storage_type = "standard"

# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip = false
nfs_vm_admin         = "nfsuser"
nfs_raid_disk_size   = 128
