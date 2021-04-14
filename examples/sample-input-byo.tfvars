# !NOTE! - These are only a subset of variables.tf provided for sample.
# Customize this file to add any variables from 'variables.tf' that you want 
# to change their default values. 

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                  = "<prefix-value>"
location                = "<gcp-zone-or-region>" # e.g., "us-east1-b""
project                 = "<gcp-project>"
service_account_keyfile = "<service-account-json-file>"
ssh_public_key          = "~/.ssh/id_rsa.pub"
#
# ****************  REQUIRED VARIABLES  ****************

# Source address ranges to allow client admin access to the cloud resources
default_public_access_cidrs = [] # e.g., ["123.45.6.89/32"]

# Bring your own existing resources
vpc_name        = "existing-vpc-namec"
subnet_names    = { 
  gke                     = "<existing-subnet-name-for-gke>"
  gke_pods_range_name     = "<existing-secondary-ip-range-for-pods-in-gke-subnet>"
  gke_services_range_name = "<existing-secondary-ip-range-for=-services-in-gke-subnet>"
  misc                    = "<existing-subnet-name-for-additional-vms>" 
}
nat_address_name = "<existing-nat-ip-address-name>"

# add labels to the created resources
tags = {} # e.g., { "key1" = "value1", "key2" = "value2" }

# Postgres config
create_postgres                  = true # set this to "false" when using internal Crunchy Postgres
postgres_ssl_enforcement_enabled = false
postgres_administrator_password  = "mySup3rS3cretPassw0rd"

# GKE config
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
  connect = {
    "vm_type"      = "n1-highmem-16"
    "os_disk_size" = 200
    "min_nodes"    = 1
    "max_nodes"    = 1
    "node_taints"  = ["workload.sas.com/class=connect:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "connect"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "local_ssd_count"   = 0
    "accelerator_count" = 0
    "accelerator_type"   = ""
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
