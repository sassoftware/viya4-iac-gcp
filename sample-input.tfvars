#!NOTE!# These are only a subset of inputs from variables.tf
# Customize this file to add any more inputs from 'variables.tf' file that you want to change 
# and change the values according to your need
prefix                          = "viya-tst1"
location                        = "us-east1-b"
#
# If you provide a public key this will be used for all vm's created
# If a public key is not provided as public_key will be generated along
# with it's private_key counter parts. This will also generated outpout
# for the articated associated with this key.
#
ssh_public_key                  = "~/.ssh/id_rsa.pub"
postgres_administrator_password = "GoSASViya4"

# GKE Config
kubernetes_version                    = "1.18.6-gke.4801"
cluster_endpoint_public_access_cidrs  = []
default_nodepool_node_count           = 2
default_nodepool_vm_type              = "n1-standard-1"
tags                                  = { project_name = "viya", environment = "sampel-std" }

# GKE Node Pools config
create_cas_nodepool       = true
create_compute_nodepool   = true
create_stateless_nodepool = true
create_stateful_nodepool  = true

# Postgres config
create_postgres           = true

# Storage for Viya Compute Services
storage_type = "standard"
# Supported storage_type values
#    "standard" - Custom managed NFS Server VM and disks
#    "ha"     - Azure NetApp Files managed service

# Jump Box
create_jump_vm        = false    # implied when storage_type = "standard"
jump_vm_admin         = "jumpuser"
create_jump_public_ip = false

# nfs vm gets created if storage_type = "standard"
nfs_vm_admin          = "nfsuser"
nfs_raid_disk_size    = 64
create_nfs_public_ip  = false