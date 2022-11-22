# !NOTE! - These are only a subset of CONFIG-VARS.md provided for sample.
# Customize this file to add any variables from 'CONFIG-VARS.md' that you want 
# to change their default values.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
# ****************  REQUIRED VARIABLES  ****************

# GKE config
kubernetes_version         = "1.23.8-gke.1900"
default_nodepool_min_nodes = 1
default_nodepool_vm_type   = "n2-standard-2"

## Cluster Node Pools config - mimimal
cluster_node_pool_mode = "minimal"
node_pools = {
  cas = {
    "vm_type"      = "n2-highmem-4"
    "os_disk_size" = 200
    "min_nodes"    = 0
    "max_nodes"    = 5
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "local_ssd_count"   = 0
    "accelerator_count" = 0
    "accelerator_type"  = ""
  },
  generic = {
    "vm_type"      = "n2-standard-8"
    "os_disk_size" = 200
    "min_nodes"    = 0
    "max_nodes"    = 5
    "node_taints"  = []
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "local_ssd_count"   = 0
    "accelerator_count" = 0
    "accelerator_type"  = ""
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

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
postgres_servers = {
  default = {},
}

# Select a kubernetes version based on channel or exact version. Google
# does not allow one to pick both. By default the value is set to 'latest'
# kubernetes_channel = "RAPID" # Which currently supports 1.24
# kubernetes_version = "1.23.8-gke.1900"

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.
#
# If you are not working from a machine on the SAS Cary Network, you can always use your own public ip:
# Use the IP reported in https://ifconfig.me/ and append "/32", e.g. 1.2.3.4/32
# For a list of the CIDRs of other SAS networks, see http://mom.unx.sas.com/net/InetAddrs.html
#
# !NOTE! - When using Terraform Cloud you must set your access_cidrs to ["0.0.0.0/0"]
#          in order to work. They do not publish their 'helper' agent IPs or assign those
#          per account so no way to predict those values when setting up access CIDRs.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = [
  "0.0.0.0/0",
]
# default_public_access_cidrs = []
create_static_kubeconfig          = true
# **************  RECOMMENDED  VARIABLES  ***************

# User variables
tf_enterprise_integration_enabled = true
