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
    "min_nodes"    = 2
    "max_nodes"    = 3
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "local_ssd_count" = 0
  },
  compute = {
    "vm_type"      = "n1-highmem-16"
    "os_disk_size" = 200
    "min_nodes"    = 2
    "max_nodes"    = 3
    "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"       = "compute"
      "launcher.sas.comprepullImage" = "sas-programming-environment"
    }
    "local_ssd_count" = 0
  },
  connect = {
    "vm_type"      = "n1-highmem-16"
    "os_disk_size" = 200
    "min_nodes"    = 2
    "max_nodes"    = 3
    "node_taints"  = ["workload.sas.com/class=connect:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "connect"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "local_ssd_count" = 0
  },
  stateless = {
    "vm_type"      = "e2-standard-16"
    "os_disk_size" = 200
    "min_nodes"    = 2
    "max_nodes"    = 3
    "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
    "local_ssd_count" = 0
  },
  stateful = {
    "vm_type"      = "e2-standard-8"
    "os_disk_size" = 200
    "min_nodes"    = 2
    "max_nodes"    = 3
    "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
    "local_ssd_count" = 0
  }
}
# Jump Box
create_jump_public_ip = true
jump_vm_admin         = "jumpuser"

# Storage for Viya Compute Services
# Supported storage_type values
#    "standard" - Custom managed NFS Server VM and disks
#    "ha"       - Google Filestore  
storage_type = "ha"
