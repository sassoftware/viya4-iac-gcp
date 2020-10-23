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

# GKE config
# VERSIONS: gcloud container get-server-config
#           https://cloud.google.com/kubernetes-engine/docs/release-notes
kubernetes_version                   = "1.18.9-gke.1501"
kubernetes_channel                   = "RAPID"
default_nodepool_node_count          = 2
default_nodepool_vm_type             = "n1-standard-1"

# Node Pools config
node_pools = {
   cas = {
      "machine_type"   = "n1-highmem-16"
      "os_disk_size"   = 200
      "min_node_count" = 1
      "max_node_count" = 1
      "node_taints"    = ["workload.sas.com/class=cas:NoSchedule"]
      "node_labels" = {
         "workload.sas.com/class" = "cas"
      }
      "local_ssd_count" = 0
   },
   compute = {
      "machine_type"   = "n1-highmem-16"
      "os_disk_size"   = 200
      "min_node_count" = 1
      "max_node_count" = 1
      "node_taints"    = ["workload.sas.com/class=compute:NoSchedule"]
      "node_labels" = {
         "workload.sas.com/class"        = "compute"
         "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
      "local_ssd_count" = 0
   },
   connect = {
      "machine_type"   = "n1-highmem-16"
      "os_disk_size"   = 200
      "min_node_count" = 1
      "max_node_count" = 1
      "node_taints"    = ["workload.sas.com/class=connect:NoSchedule"]
      "node_labels" = {
         "workload.sas.com/class"        = "connect"
         "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
      "local_ssd_count" = 0
   },
   stateless = {
      "machine_type"   = "e2-standard-16"
      "os_disk_size"   = 200
      "min_node_count" = 1
      "max_node_count" = 2
      "node_taints"    = ["workload.sas.com/class=stateless:NoSchedule"]
      "node_labels" = {
         "workload.sas.com/class" = "stateless"
      }
      "local_ssd_count" = 0
   },
   stateful = {
      "machine_type"   = "e2-standard-8"
      "os_disk_size"   = 200
      "min_node_count" = 1
      "max_node_count" = 3
      "node_taints"    = ["workload.sas.com/class=stateful:NoSchedule"]
      "node_labels" = {
         "workload.sas.com/class" = "stateful"
      }
      "local_ssd_count" = 0
   }
}


# Jump Box
create_jump_public_ip          = true
jump_vm_admin                  = "jumpuser"

# Storage for SAS Viya CAS/Compute
storage_type = "standard"
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip  = false
nfs_vm_admin          = "nfsuser"
nfs_raid_disk_size    = 128
