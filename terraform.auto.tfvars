# !NOTE! - These are only a subset of CONFIG-VARS.md provided for sample.
# Customize this file to add any variables from 'CONFIG-VARS.md' that you want 
# to change their default values.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                  = "thpang-dev"
location                = "us-east1-b" # e.g., "us-east1-b"
project                 = "rdorgasub5"
service_account_keyfile = "~/.google/devops-svc-account-admin.json"
# ssh_public_key          = "~/.ssh/id_rsa.pub"
# Tags for cloud resources
# Note, when 'resourceowner' tag is not provided, SAS IT monitoring process will add later, that could create differences with your local Terraform state
tags = {
  "resourceowner" = "thpang",
  "project_name"  = "thpang-dev",
  "environment"   = "thpang-dev"
}
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

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = ["0.0.0.0/0",
  # "149.173.0.0/16", "194.206.69.176/28", "109.232.56.224/27", "62.255.11.0/29",
  # "88.202.174.192/29", "137.221.139.0/24", "212.103.250.112/29", "88.151.216.240/29",
  # "121.244.109.0/24", "125.21.192.0/29", "121.243.77.24/29", "106.120.85.32/28",
  # "113.34.83.240/29", "75.2.98.97/32", "99.83.150.238/32", "52.86.200.106/32",
  # "52.86.201.227/32", "52.70.186.109/32", "44.236.246.186/32", "54.185.161.84/32",
  # "44.238.78.236/32", "52.86.200.106/32", "52.86.201.227/32", "52.70.186.109/32",
  # "44.236.246.186/32", "54.185.161.84/32", "44.238.78.236/32", "52.86.200.106/32",
  # "52.86.201.227/32", "52.70.186.109/32", "44.236.246.186/32", "54.185.161.84/32",
  # "44.238.78.236/32",
]
# default_public_access_cidrs = []
create_static_kubeconfig = true
# **************  RECOMMENDED  VARIABLES  ***************

# User variables
tf_cloud_integration_enabled = true
