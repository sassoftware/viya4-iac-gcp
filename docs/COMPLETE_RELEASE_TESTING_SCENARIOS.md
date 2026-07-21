# viya4-iac-gcp – Complete Release Testing Coverage

**Purpose:** Comprehensive guide for all test scenarios that should be covered when releasing the viya4-iac-gcp code. This document defines the complete testing scope, organized by category and complexity.

---

## Release Testing Scope Overview

### Testing Tiers by Release Type

| Release Type | Minimum Tests | Extended Tests | Full Regression |
|---|---|---|---|
| **Patch** (0.1.0 → 0.1.1) | Scenarios 1, 2, 3 | + 2–3 related scenarios | Run if code touches core modules |
| **Minor** (0.1.0 → 0.2.0) | Scenarios 1–6 | + 50% of matrix (10 cases) | Recommended |
| **Major** (0.1.0 → 1.0.0) | Scenarios 1–10 | **All 20 cases** | **Required** |

---

## Complete tfvars Configurations for Each Scenario

Use these tfvars templates directly in your test runs. Replace `<your-project-id>`, `<your-sa-json>`, etc. with actual values.

### Base Variables (Required for All Scenarios)
```hcl
# These are common to all scenarios – customize per test
prefix                  = "test-scenario-X"              # Change X for each scenario
location                = "us-east1-b"                  # or us-east1 for regional
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"
tags = {
  "environment" = "test"
  "release"     = "v0.X.X"
}
```

### Scenario 1.1a – Single-Zone + NFS (MUST TEST)
```hcl
# File: test-scenario-1.1a.tfvars
prefix                  = "test-nfs-zonal"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

# GKE config
kubernetes_version      = "1.34"
regional                = false
kubernetes_channel      = "UNSPECIFIED"

# Storage
storage_type            = "standard"
storage_type_backend    = "nfs"
create_nfs_public_ip    = false
nfs_vm_admin            = "nfsuser"
nfs_vm_type             = "n2-highmem-4"
nfs_raid_disk_size      = 500

# Node pools (default)
default_nodepool_vm_type = "n2-highmem-8"
default_nodepool_min_nodes = 1
default_nodepool_max_nodes = 5

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 5
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 4
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 4
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

# PostgreSQL
postgres_servers = {
  default = {}
}

# Jump box
create_jump_public_ip = true
jump_vm_admin         = "jumpuser"
```

### Scenario 1.1b – Single-Zone + NFS + Minimal Pools
```hcl
# File: test-scenario-1.1b.tfvars
prefix                  = "test-nfs-minimal"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "1.34"
regional                = false
kubernetes_channel      = "UNSPECIFIED"

storage_type            = "standard"
storage_type_backend    = "nfs"

cluster_node_pool_mode  = "minimal"  # Key difference: minimal mode

default_nodepool_vm_type = "n2-highmem-8"
default_nodepool_min_nodes = 1

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 0
    max_nodes    = 5
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  generic = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 0
    max_nodes    = 5
    node_taints  = []
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

postgres_servers = {
  default = {}
}

create_jump_public_ip = true
```

### Scenario 1.1c – Single-Zone + NFS + Connect Pool
```hcl
# File: test-scenario-1.1c.tfvars
prefix                  = "test-nfs-connect"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "1.34"
regional                = false
kubernetes_channel      = "UNSPECIFIED"

storage_type            = "standard"
storage_type_backend    = "nfs"

default_nodepool_vm_type = "n2-highmem-8"

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  connect = {  # NEW POOL
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=connect:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "connect" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

postgres_servers = { default = {} }
create_jump_public_ip = true
```

### Scenario 1.2a – Single-Zone + Filestore
```hcl
# File: test-scenario-1.2a.tfvars
prefix                  = "test-filestore-zonal"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "1.34"
regional                = false
kubernetes_channel      = "UNSPECIFIED"

storage_type            = "standard"
storage_type_backend    = "filestore"  # Key difference: filestore instead of nfs

default_nodepool_vm_type = "n2-highmem-8"

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

postgres_servers = { default = {} }
create_jump_public_ip = true
```

### Scenario 1.3a – Single-Zone + NetApp HA
```hcl
# File: test-scenario-1.3a.tfvars
prefix                  = "test-netapp-zonal"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "1.34"
regional                = false
kubernetes_channel      = "UNSPECIFIED"

storage_type            = "ha"  # HA storage
storage_type_backend    = "netapp"  # NetApp backend

netapp_service_level    = "FLEX"
netapp_capacity_gib     = 2048
netapp_protocols        = ["NFSV3"]
enable_netapp_dns       = false  # Optional for single zone

default_nodepool_vm_type = "n2-highmem-8"

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

postgres_servers = { default = {} }
create_jump_public_ip = true
```

### Scenario 1.3b – Multi-Zone + NetApp + Regional Control Plane (MUST TEST)
```hcl
# File: test-scenario-1.3b.tfvars
prefix                  = "test-netapp-multizone"
location                = "us-east1"  # Region, not zone
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "1.34"
regional                = true  # Regional control plane
kubernetes_channel      = "REGULAR"

storage_type            = "ha"
storage_type_backend    = "netapp"

netapp_service_level    = "FLEX"
netapp_capacity_gib     = 2048
netapp_protocols        = ["NFSV3"]
enable_netapp_dns       = true  # Enable DNS for zone failover
netapp_dns_zone_name    = "netapp.internal"
netapp_dns_record_ttl   = 300

# Multi-zone configuration
default_nodepool_locations = "us-east1-b,us-east1-c,us-east1-d"
nodepools_locations        = "us-east1-b,us-east1-c,us-east1-d"

default_nodepool_vm_type = "n2-highmem-8"
default_nodepool_min_nodes = 2

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 2
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 2
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 2
    max_nodes    = 4
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 2
    max_nodes    = 4
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

postgres_servers = { default = {} }
create_jump_public_ip = true
```

### Scenario 2.2 – K8s STABLE Channel
```hcl
# File: test-scenario-2.2.tfvars
prefix                  = "test-k8s-stable"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "latest"  # Will use STABLE default
kubernetes_channel      = "STABLE"  # Key difference

regional                = false
storage_type            = "standard"
storage_type_backend    = "nfs"

default_nodepool_vm_type = "n2-highmem-8"

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

postgres_servers = { default = {} }
create_jump_public_ip = true
```

### Scenario 3.3 – Optional CAS (Programming-Only)
```hcl
# File: test-scenario-3.3.tfvars
prefix                  = "test-no-cas"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "1.34"
regional                = false
kubernetes_channel      = "UNSPECIFIED"

storage_type            = "standard"
storage_type_backend    = "nfs"

default_nodepool_vm_type = "n2-highmem-8"

node_pools = {
  # NO CAS POOL – Key difference
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

postgres_servers = { default = {} }
create_jump_public_ip = true
```

### Scenario 3.4 – SingleStore Node Pool
```hcl
# File: test-scenario-3.4.tfvars
prefix                  = "test-singlestore"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "1.34"
regional                = false
kubernetes_channel      = "UNSPECIFIED"

storage_type            = "ha"
storage_type_backend    = "netapp"

default_nodepool_vm_type = "n2-highmem-8"

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  singlestore = {  # NEW POOL
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 2
    max_nodes    = 7
    node_taints  = ["workload.sas.com/class=singlestore:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "singlestore" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
}

postgres_servers = { default = {} }
create_jump_public_ip = true
```

### Scenario 4.4 – Bring-Your-Own Network (BYO)
```hcl
# File: test-scenario-4.4.tfvars
prefix                  = "test-byo-network"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "1.34"
regional                = false
kubernetes_channel      = "UNSPECIFIED"

# BYO Network configuration – Key difference
vpc_name = "my-existing-vpc"  # Pre-existing VPC
subnet_names = {
  gke                     = "my-gke-subnet"
  gke_pods_range_name     = "gke-pods"
  gke_services_range_name = "gke-services"
  misc                    = "my-misc-subnet"
}
nat_address_name = "my-nat-ip"  # Pre-existing NAT IP

storage_type            = "standard"
storage_type_backend    = "nfs"

default_nodepool_vm_type = "n2-highmem-8"

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 3
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

postgres_servers = { default = {} }
create_jump_public_ip = false  # Usually no public jump in BYO networks
```

### Scenario 7.1 – GKE Network Policies Enabled
```hcl
# File: test-scenario-7.1.tfvars
prefix                  = "test-netpolicy-enabled"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "1.34"
regional                = false
kubernetes_channel      = "UNSPECIFIED"

gke_network_policy      = true  # Key difference: enable network policies

storage_type            = "standard"
storage_type_backend    = "nfs"

default_nodepool_vm_type = "n2-highmem-8"

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

postgres_servers = { default = {} }
create_jump_public_ip = true
```

### Scenario 7.3 – GPU / Accelerators Enabled
```hcl
# File: test-scenario-7.3.tfvars
prefix                  = "test-gpu-enabled"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "1.34"
regional                = false
kubernetes_channel      = "UNSPECIFIED"

storage_type            = "standard"
storage_type_backend    = "nfs"

default_nodepool_vm_type = "n2-highmem-8"

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  analytics = {  # GPU workload pool
    vm_type      = "n2-highmem-8"
    os_disk_size = 200
    min_nodes    = 0
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=analytics:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "analytics" }
    local_ssd_count   = 0
    accelerator_count = 1  # GPU count
    accelerator_type  = "nvidia-tesla-k80"  # GPU type
  }
}

postgres_servers = { default = {} }
create_jump_public_ip = true
```

### Scenario 5.2 – No PostgreSQL (Infrastructure Only)
```hcl
# File: test-scenario-5.2.tfvars
prefix                  = "test-no-postgres"
location                = "us-east1-b"
project                 = "<your-gcp-project-id>"
service_account_keyfile = "<path-to-service-account.json>"
ssh_public_key          = "~/.ssh/id_rsa.pub"

kubernetes_version      = "1.34"
regional                = false
kubernetes_channel      = "UNSPECIFIED"

storage_type            = "ha"
storage_type_backend    = "netapp"

# NO POSTGRES_SERVERS BLOCK – Key difference
# postgres_servers = null  # Or simply omit this variable

default_nodepool_vm_type = "n2-highmem-8"

node_pools = {
  cas = {
    vm_type      = "n2-highmem-16"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=cas:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "cas" }
    local_ssd_count   = 2
    accelerator_count = 0
    accelerator_type  = ""
  }
  compute = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=compute:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "compute" }
    local_ssd_count   = 1
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateless = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateless:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateless" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
  stateful = {
    vm_type      = "n2-highmem-4"
    os_disk_size = 200
    min_nodes    = 1
    max_nodes    = 2
    node_taints  = ["workload.sas.com/class=stateful:NoSchedule"]
    node_labels  = { "workload.sas.com/class" = "stateful" }
    local_ssd_count   = 0
    accelerator_count = 0
    accelerator_type  = ""
  }
}

create_jump_public_ip = true
```

---

## Category 1: Storage Type Permutations

All storage configurations must be tested with various GKE topologies.

### 1.1 – Standard (NFS VM Backend)
- **Scenario 1.1a:** Single-zone + NFS (default)
  - `storage_type = "standard"`, `storage_type_backend = "nfs"`
  - `regional = false` (zonal control plane)
  - Single node pool locations
  - ✅ **MUST TEST** – baseline use case
  
- **Scenario 1.1b:** Single-zone + NFS + Minimal pools
  - Uses `cluster_node_pool_mode = "minimal"` (cas + generic only)
  - Validates minimal footprint
  - ✅ **RECOMMENDED**

- **Scenario 1.1c:** Single-zone + NFS + Custom node pools
  - Adds `connect` node pool for SAS/CONNECT workloads
  - Or adds `singlestore` node pool for SingleStore workloads
  - Validates custom pool integration
  - ✅ **RECOMMENDED**

### 1.2 – Standard (Filestore Backend)
- **Scenario 1.2a:** Single-zone + Filestore (zonal)
  - `storage_type = "standard"`, `storage_type_backend = "filestore"`
  - Validates Google Filestore as alternative to NFS VM
  - **Cost:** Similar to NFS VM; simpler management
  - ✅ **SHOULD TEST**

- **Scenario 1.2b:** Single-zone + Filestore + Postgres
  - With `postgres_servers = { default = {} }`
  - ✅ **SHOULD TEST**

### 1.3 – HA (NetApp Backend, Zone-Redundant)
- **Scenario 1.3a:** Single-zone + NetApp
  - `storage_type = "ha"`, `storage_type_backend = "netapp"`
  - `regional = false` (zonal control plane allowed with single zone)
  - Validates NetApp provisioning in single zone
  - ✅ **MUST TEST**

- **Scenario 1.3b:** Multi-zone + NetApp (regional control plane)
  - `storage_type = "ha"`, `storage_type_backend = "netapp"`
  - `regional = true`
  - `default_nodepool_locations = "us-east1-b,us-east1-c,us-east1-d"` (3 zones)
  - `nodepools_locations = "us-east1-b,us-east1-c,us-east1-d"`
  - Validates NetApp cross-zone replication (CZR)
  - ✅ **MUST TEST** – critical for HA deployments

- **Scenario 1.3c:** Multi-zone + NetApp + NetApp DNS enabled
  - `enable_netapp_dns = true`
  - `netapp_dns_zone_name = "netapp.internal"`
  - Validates DNS failover mechanism
  - ✅ **MUST TEST** – production HA requirement

- **Scenario 1.3d:** Multi-zone + NetApp + DNS disabled
  - `enable_netapp_dns = false`
  - Validates DNS is truly optional
  - ✅ **SHOULD TEST**

---

## Category 2: Kubernetes Channel & Version Permutations

GKE channels control auto-upgrade behavior. Test all to ensure compatibility.

### 2.1 – Channel: UNSPECIFIED (No auto-upgrade)
- **Scenario 2.1a:** K8s version `latest`
  - `kubernetes_channel = "UNSPECIFIED"`, `kubernetes_version = "latest"`
  - GKE uses default static version
  - ✅ **MUST TEST**

- **Scenario 2.1b:** K8s version pinned minor (e.g., `1.34`)
  - `kubernetes_channel = "UNSPECIFIED"`, `kubernetes_version = "1.34"`
  - GKE selects latest patch within `1.34.x`
  - ✅ **MUST TEST**

- **Scenario 2.1c:** K8s version pinned full (e.g., `1.30.5-gke.123`)
  - `kubernetes_channel = "UNSPECIFIED"`, `kubernetes_version = "1.30.5-gke.123"`
  - Specific patch pinning
  - ✅ **SHOULD TEST**

### 2.2 – Channel: STABLE (Latest stable release)
- **Scenario 2.2a:** STABLE channel + latest version
  - `kubernetes_channel = "STABLE"`, `kubernetes_version = "latest"`
  - GKE auto-selects STABLE default
  - ✅ **SHOULD TEST**

### 2.3 – Channel: REGULAR (Default, releases every few weeks)
- **Scenario 2.3a:** REGULAR channel + latest version
  - `kubernetes_channel = "REGULAR"`, `kubernetes_version = "latest"`
  - GKE auto-selects REGULAR default
  - ✅ **MUST TEST** – most common in production

### 2.4 – Channel: RAPID (Latest features, may be unstable)
- **Scenario 2.4a:** RAPID channel + latest version
  - `kubernetes_channel = "RAPID"`, `kubernetes_version = "latest"`
  - Tests bleeding-edge GKE
  - ✅ **NICE TO HAVE** – optional for early adopters

### 2.5 – Channel: EXTENDED (LTS support, slower updates)
- **Scenario 2.5a:** EXTENDED channel + latest version
  - `kubernetes_channel = "EXTENDED"`, `kubernetes_version = "latest"`
  - Tests LTS stability
  - ✅ **NICE TO HAVE** – enterprises may use

---

## Category 3: Node Pool Permutations

All node pool combinations must be validated.

### 3.1 – Default Node Pools
- **Scenario 3.1a:** cas + compute + stateless + stateful (standard)
  - All 4 workload-class taints present
  - ✅ **MUST TEST**

### 3.2 – Minimal Node Pools
- **Scenario 3.2a:** cas + generic (minimal mode)
  - `cluster_node_pool_mode = "minimal"`
  - ✅ **SHOULD TEST**

### 3.3 – Optional CAS (Programming-only)
- **Scenario 3.3a:** No CAS node pool
  - `node_pools` excludes `cas`
  - Validates programming-only deployments
  - ✅ **SHOULD TEST**

### 3.4 – Extended Node Pools
- **Scenario 3.4a:** Add `connect` pool
  - For SAS/CONNECT workloads
  - ✅ **SHOULD TEST**

- **Scenario 3.4b:** Add `singlestore` pool
  - For SingleStore database workloads
  - ✅ **SHOULD TEST**

- **Scenario 3.4c:** Add both `connect` + `singlestore`
  - Maximum node pool complexity
  - ✅ **NICE TO HAVE**

### 3.5 – Per-Nodepool Zone Overrides
- **Scenario 3.5a:** Each pool in different zones
  - `node_pools.<name>.node_locations` per pool
  - cas: 2 zones, compute: 1 zone, stateless: 3 zones, stateful: 2 zones
  - Validates per-pool zone control
  - ✅ **SHOULD TEST**

---

## Category 4: Cluster Topology Permutations

### 4.1 – Control Plane: Zonal
- **Scenario 4.1a:** Single zone, zonal control plane (default)
  - `regional = false`
  - `location = "us-east1-b"` (single zone)
  - ✅ **MUST TEST**

### 4.2 – Control Plane: Regional
- **Scenario 4.2a:** Regional control plane + single-zone nodes
  - `regional = true`
  - `location = "us-east1"` (region)
  - `default_nodepool_locations = "us-east1-b"` (single zone)
  - HA control plane, non-HA worker nodes
  - ✅ **SHOULD TEST**

- **Scenario 4.2b:** Regional control plane + multi-zone nodes
  - `regional = true`
  - `location = "us-east1"`
  - `default_nodepool_locations = "us-east1-b,us-east1-c,us-east1-d"`
  - Full regional HA
  - ✅ **MUST TEST** – enterprise requirement

### 4.3 – Network Topology: VPC Creation
- **Scenario 4.3a:** Default (Terraform creates VPC)
  - `vpc_name` not specified
  - Terraform creates new VPC with CIDR ranges
  - ✅ **MUST TEST**

### 4.4 – Network Topology: Bring-Your-Own (BYO)
- **Scenario 4.4a:** Pre-existing VPC + subnets
  - `vpc_name = "<existing-vpc>"`
  - `subnet_names = { gke = "...", misc = "..." }`
  - `nat_address_name = "<existing-nat-ip>"`
  - Validates BYO network path
  - ✅ **MUST TEST** – enterprise integration requirement

- **Scenario 4.4b:** BYO VPC + Custom CIDR ranges
  - Non-standard IP ranges (e.g., 172.x.x.x instead of 10.x.x.x)
  - Validates CIDR flexibility
  - ✅ **SHOULD TEST**

---

## Category 5: Database (PostgreSQL) Permutations

### 5.1 – PostgreSQL: Included
- **Scenario 5.1a:** Create default Postgres server
  - `postgres_servers = { default = {} }`
  - Uses all defaults from `postgres_server_defaults`
  - ✅ **MUST TEST**

- **Scenario 5.1b:** Custom Postgres version
  - `postgres_servers = { default = { postgres_version = "15" } }`
  - Validates version override
  - ✅ **SHOULD TEST**

- **Scenario 5.1c:** Multiple Postgres servers
  - `postgres_servers = { default = {}, analytics = { ... } }`
  - Validates multi-DB support
  - ✅ **NICE TO HAVE**

### 5.2 – PostgreSQL: Excluded
- **Scenario 5.2a:** No Postgres block
  - `postgres_servers = null` or undefined
  - Infrastructure-only deployment
  - ✅ **SHOULD TEST**

---

## Category 6: VM & Resource Sizing Permutations

### 6.1 – Default VM Sizing
- **Scenario 6.1a:** Use provided defaults
  - `default_nodepool_vm_type = "n2-highmem-8"`
  - Node pools: cas=n2-highmem-16, compute=n2-highmem-4, etc.
  - ✅ **MUST TEST**

### 6.2 – Custom VM Sizing
- **Scenario 6.2a:** Reduce VM size (cost optimization)
  - `default_nodepool_vm_type = "n2-standard-4"`
  - cas: n2-standard-8 (smaller)
  - Validates smaller deployments
  - ✅ **SHOULD TEST**

- **Scenario 6.2b:** Increase VM size (performance)
  - `default_nodepool_vm_type = "n2-highmem-16"`
  - cas: n2-highmem-32, compute: n2-highmem-8
  - Validates larger deployments
  - ✅ **NICE TO HAVE**

### 6.3 – Scaling Configuration
- **Scenario 6.3a:** Auto-scaling enabled
  - `min_nodes = 1, max_nodes = 5` (default)
  - Validates cluster can scale
  - ✅ **MUST TEST**

- **Scenario 6.3b:** Fixed scaling (no auto-scale)
  - `min_nodes = 3, max_nodes = 3` (all pools)
  - Validates static clusters
  - ✅ **SHOULD TEST**

- **Scenario 6.3c:** Aggressive scaling
  - `min_nodes = 0, max_nodes = 10` (for on-demand workloads)
  - Validates scale-to-zero scenarios
  - ✅ **NICE TO HAVE**

---

## Category 7: Advanced Features

### 7.1 – Network Policies
- **Scenario 7.1a:** Enable GKE Network Policies
  - `gke_network_policy = true`
  - Validates CNI network policy enforcement
  - ✅ **SHOULD TEST** – security best practice

- **Scenario 7.1b:** Disable Network Policies (default)
  - `gke_network_policy = false`
  - ✅ **MUST TEST**

### 7.2 – Local SSDs
- **Scenario 7.2a:** CAS pool with local SSDs
  - `local_ssd_count = 2` (cas pool)
  - Validates high-performance storage
  - ✅ **SHOULD TEST** – for CAS workloads

- **Scenario 7.2b:** No local SSDs
  - All pools: `local_ssd_count = 0`
  - Validates network-only storage
  - ✅ **SHOULD TEST**

### 7.3 – GPU / Accelerators
- **Scenario 7.3a:** Enable GPUs on compute pool
  - `accelerator_count = 1, accelerator_type = "nvidia-tesla-k80"`
  - Validates GPU workload support
  - ✅ **NICE TO HAVE** – optional for analytics

- **Scenario 7.3b:** No accelerators (default)
  - `accelerator_count = 0`
  - ✅ **MUST TEST**

### 7.4 – Jump VM
- **Scenario 7.4a:** Create jump VM with public IP
  - `create_jump_public_ip = true`
  - Validates SSH access for cluster administration
  - ✅ **SHOULD TEST**

- **Scenario 7.4b:** No jump VM / private only
  - `create_jump_public_ip = false`
  - ✅ **SHOULD TEST**

---

## Category 8: Validation & Destruction

### 8.1 – State Management
- **Scenario 8.1a:** Complete state lifecycle
  - init → plan → apply → destroy
  - Validates state is correctly managed
  - ✅ **MUST TEST** for every scenario

- **Scenario 8.1b:** Refresh + Reapply
  - `terraform refresh` after apply
  - `terraform apply` again without changes
  - Validates idempotency
  - ✅ **SHOULD TEST**

### 8.2 – Error Handling
- **Scenario 8.2a:** Invalid variable combinations
  - Test validation rules (e.g., `storage_type=ha` requires `regional=true` with multi-zone)
  - Terraform should reject invalid configs
  - ✅ **MUST TEST**

- **Scenario 8.2b:** Quota exceeded
  - Simulate GCP quota limits
  - Validate error messages
  - ✅ **NICE TO HAVE**

---

## Complete Test Matrix Summary

### Release Testing Roadmap

```
┌─ PATCH RELEASE (Quick)
│  ├─ Scenario 1: Zonal NFS (5–10 min check)
│  ├─ Scenario 2: Multi-zone NetApp (5–10 min check)
│  └─ Scenario 3: BYO Network (5–10 min check)
│  Total: ~20–30 min
│
├─ MINOR RELEASE (Standard)
│  ├─ All patch scenarios (1–3)
│  ├─ + K8s channel tests (STABLE, REGULAR, RAPID)
│  ├─ + Filestore backend test
│  ├─ + Optional CAS test
│  ├─ + SingleStore pool test
│  └─ + BYO + Custom CIDR test
│  Total: ~4–5 hours, 10–12 scenarios
│
└─ MAJOR RELEASE (Comprehensive)
   ├─ All minor scenarios
   ├─ + All 20 regression test matrix cases
   ├─ + Edge cases (per-pool zones, GPU, network policies)
   ├─ + Extended PostgreSQL variants
   ├─ + Scaling permutations
   └─ + Load testing on large clusters (optional)
   Total: ~8–12 hours, all 20+ scenarios
```

---

## Pre-Release Checklist (All Scenarios)

Before running any infrastructure tests:

- [ ] **Code Quality**
  - `terraform fmt -check` passes on all modules
  - `terraform validate` passes on root + all modules
  - No linting warnings from `tflint` (if configured)
  - No deprecated GCP resource usage

- [ ] **Documentation**
  - README.md updated with new features
  - CONFIG-VARS.md reflects all variable changes
  - Example `.tfvars` files are syntactically valid HCL
  - CHANGELOG.md documents breaking changes

- [ ] **Version Constraints**
  - `versions.tf` specifies reasonable Terraform version (e.g., >= 1.5)
  - Google provider version constraints are not too strict (e.g., >= 6.0, < 7.0)
  - Avoid pinning patch versions

- [ ] **Security & Secrets**
  - No hard-coded credentials in examples
  - No API keys in `.tfvars` templates
  - Service account key file path is templated (`<your-sa-json>`)
  - SSH public key path is templated (`~/.ssh/id_rsa.pub`)

- [ ] **Module Dependencies**
  - All local modules referenced correctly
  - No circular dependencies
  - Module outputs are documented

---

## Per-Scenario Execution Template

For **each** scenario, follow this template:

```bash
#!/bin/bash
SCENARIO_NAME="<scenario-name>"
PREFIX="test-${SCENARIO_NAME}-$(date +%s)"

echo "=== Starting $SCENARIO_NAME ==="

# 1. Pre-flight
export PROJECT_ID="<gcp-project>"
export SA_KEYFILE="<path-to-sa.json>"
gcloud config set project $PROJECT_ID

# 2. Create tfvars (from examples or custom)
cp examples/sample-input-*.tfvars /tmp/test.tfvars
sed -i "s/PREFIX=.*/PREFIX=$PREFIX/" /tmp/test.tfvars

# 3. Terraform
terraform init
terraform plan -var-file=/tmp/test.tfvars -out=/tmp/plan.tfplan
# VERIFY: Resource count, module outputs, etc.
terraform apply /tmp/plan.tfplan

# 4. Post-deployment validation
kubectl cluster-info
kubectl get nodes
# VERIFY: All nodes Ready, system pods Running

# 5. Storage test
# VERIFY: PVC mounts, data persists

# 6. Cleanup
terraform destroy -auto-approve
# VERIFY: All resources deleted

echo "✅ $SCENARIO_NAME passed"
```

---

## Scenario Priority Matrix

| Priority | Scenarios | Use Case |
|---|---|---|
| **P0 – MUST PASS** | 1, 2, 3, 4, 5, 6, 7 | Core functionality; every release |
| **P1 – SHOULD PASS** | 8, 9, 10, 11, 12, 13, 14, 15 | Extended features; minor+ releases |
| **P2 – NICE TO HAVE** | 16, 17, 18, 19, 20 | Edge cases; major releases |

### P0 Scenarios (Every Release)
1. Zonal + NFS (default)
2. Multi-zone + NetApp + DNS
3. BYO network + NFS
4. Regional control plane + multi-zone
5. K8s UNSPECIFIED + latest
6. K8s REGULAR + latest
7. PostgreSQL default + NFS storage

### P1 Scenarios (Minor+ Releases)
8. Single-zone + Filestore
9. Minimal node pool mode (cas + generic)
10. Optional CAS (programming-only)
11. Connect node pool
12. SingleStore node pool
13. K8s STABLE channel
14. K8s EXTENDED channel
15. GKE Network Policies enabled

### P2 Scenarios (Major Releases)
16. K8s RAPID channel (bleeding-edge)
17. GPU / Accelerators
18. Per-nodepool zone overrides
19. Scaling configurations (min/max nodes)
20. No PostgreSQL (infra-only)

---

## Cost & Time Estimates

| Release Type | Scenarios | Duration | Cost (GCP) |
|---|---|---|---|
| Patch | 3 (P0 only) | ~90 min | ~$15–20 |
| Minor | 7 + 2 related | ~3–4 hours | ~$40–60 |
| Major | 15–20 (all) | ~8–12 hours | ~$100–150 |

**Notes:**
- Times are wall-clock; can parallelize with multiple projects
- Costs assume on-demand compute; reserved instances reduce cost
- NetApp volumes add $1–2/hour; delete promptly after test
- Jump VMs (~$0.02/hour), Postgres (~$0.20/hour)

---

## Success Criteria (All Scenarios)

✅ **PASS if:**
- Terraform plan/apply complete without errors
- All GKE resources created successfully
- Nodes reach `Ready` state within 10 minutes
- All system pods (dns, logging) are `Running`
- Storage volumes mount and read/write correctly
- Postgres (if enabled) accepts connections
- Terraform destroy removes all resources

❌ **FAIL if:**
- Any Terraform errors (validation, apply, destroy)
- Nodes stuck in `Pending` or `NotReady` after 15 min
- Storage mount fails
- System pods not `Running` after 5 min
- Orphaned resources remain after destroy

---

## Recommended Release Testing Timeline

### Day 1: Code Review & Static Checks
- [ ] Peer review of changes
- [ ] Linting & validation
- [ ] Documentation review

### Day 2: P0 Scenarios (3 scenarios)
- [ ] Zonal NFS + Postgres
- [ ] Multi-zone NetApp + DNS
- [ ] BYO Network
- **Duration:** 2–3 hours
- **Decision:** Go/No-Go for P1 testing

### Day 3: P1 Scenarios (4–5 scenarios)
- [ ] Filestore backend
- [ ] Minimal pools
- [ ] Optional CAS
- [ ] Extended pools (connect, singlestore)
- [ ] K8s channel variants
- **Duration:** 4–5 hours
- **Decision:** Go/No-Go for release

### Day 4: P2 & Edge Cases (Optional)
- [ ] Per-pool zones
- [ ] GPU / Accelerators
- [ ] Scaling configs
- [ ] Load testing
- **Duration:** 3–4 hours
- **Decision:** Final sign-off

### Day 5: Release
- [ ] Tag and publish
- [ ] Update release notes
- [ ] Notify stakeholders

---

## Post-Release Validation

After release is live:

- [ ] Monitor GitHub issues / customer reports
- [ ] Verify no regression in field deployments
- [ ] Collect feedback on new features
- [ ] Plan fixes for next release (if needed)
- [ ] Schedule post-release retrospective

