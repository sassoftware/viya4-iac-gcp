# SAS Viya 4 IaC for GCP - AI Coding Agent Instructions

## Project Overview
This Terraform project provisions Google Cloud infrastructure for deploying SAS Viya 4 platform products, including GKE clusters, storage, networking, and optional PostgreSQL instances.

## Critical Architecture Concepts

### Storage Type Logic (Multi-Zone vs Single-Zone)
The project uses **conditional storage backends** based on deployment topology:
- `storage_type = "standard"` → **NFS VM only (ZONAL, single-zone only)**
- `storage_type = "ha"` → **Google NetApp Volumes (zone-redundant, required for multi-zone)**
- `storage_type = "none"` → No shared storage provisioned

**IMPORTANT - Variable Override**: A `var.storage_type_backend` variable exists in `variables.tf` (lines 195-209) but is **completely overridden** by `locals.tf` line 34. User input for this variable is ignored. This causes confusion when users see `"storage_type_backend": "nfs"` in terraform.tfstate output.

**Key Pattern**: `locals.tf` forcibly maps `storage_type` to `storage_type_backend` regardless of user input:
```terraform
# locals.tf line 34 - OVERRIDES var.storage_type_backend
storage_type_backend = (var.storage_type == "none" ? "none"
  : var.storage_type == "standard" ? "nfs"  # Always "nfs" for standard, never "filestore"
  : var.storage_type == "ha" ? "netapp" : "none")
```

**Actual Storage Backend Behavior**:
1. `storage_type = "standard"` → `local.storage_type_backend = "nfs"` → NFS VM via `modules/google_vm/` (see `vms.tf` line 19)
2. `storage_type = "ha"` → `local.storage_type_backend = "netapp"` → NetApp Volumes via `modules/google_netapp/`
3. Google Filestore is **NOT deployed** despite condition check in `main.tf` line 75: `count = var.storage_type == "standard" && local.storage_type_backend == "filestore" ? 1 : 0` (never true with current logic)

**CRITICAL**: 
- NFS VMs are **ZONAL** services—they do NOT provide zone-redundant storage
- Google Filestore (also ZONAL) is not currently deployed by this IaC despite variable/condition existing
- For Multi-Zone/HA deployments, always use `storage_type = "ha"` (NetApp Volumes)

**User Question Response - storage_type_backend in terraform.tfstate:**
**Yes, this is 100% expected.** The `var.storage_type_backend` variable exists but is **completely ignored** by the implementation. The actual backend is determined by `storage_type`:
- When `storage_type = "standard"` → `local.storage_type_backend = "nfs"` → NFS VM is deployed (not Google Filestore)
- When `storage_type = "ha"` → `local.storage_type_backend = "netapp"` → Google NetApp Volumes (zone-redundant) is deployed

The code hardcodes these mappings in `locals.tf` line 34, regardless of any value users set for `var.storage_type_backend`. This is correct behavior.

### Zone and Location Logic (`locals.tf`)
Location resolution follows this hierarchy:
1. If `var.location` is set and matches region pattern → extract region, determine if regional
2. Get zone from `var.location` (if zone format), else use `local.first_zone` from `data.google_compute_zones.available`
3. Fall back to `data.google_client_config.current.zone` if location not set

```terraform
# locals.tf lines 9-14
is_region  = var.location != "" ? var.location == regex("^[a-z0-9]*-[a-z0-9]*", var.location) : false
first_zone = length(data.google_compute_zones.available.names) > 0 ? data.google_compute_zones.available.names[0] : ""
zone = (var.location != "" ? (local.is_region ? local.first_zone : var.location) : 
        (data.google_client_config.current.zone == "" ? local.first_zone : data.google_client_config.current.zone))
```

**Multi-zone node pools**: `modules/google_netapp/locals.tf` determines multi-zone by checking if `default_nodepool_locations` contains multiple comma-separated zones.

### SAS Workload Node Pool Pattern
All node pools use **SAS-specific taints and labels** to control pod placement:
```terraform
node_taints = ["workload.sas.com/class=cas:NoSchedule"]
node_labels = { "workload.sas.com/class" = "cas" }
```
Standard workload classes: `cas`, `compute`, `stateless`, `stateful`. See `variables.tf` lines 284-340 for default definitions.

**Taint Format Conversion**: Terraform uses Kubernetes format (`NoSchedule`) but GKE API requires `NO_SCHEDULE`. Conversion happens in `locals.tf` via `taint_effects` map (lines 49-53).

**Accelerator Taints**: GPU node pools automatically add `nvidia.com/gpu=present:NoSchedule` taint (see `locals.tf` line 62).

### Node Pool Location Control
Per-nodepool zone assignment follows this fallback chain (`locals.tf` lines 64-76):
1. Use `settings.node_locations` from individual node pool config if set
2. Fall back to `var.nodepools_locations` (global setting)
3. Fall back to `local.zone` (single zone)

### Regional vs Zonal Clusters
- `regional = true` creates a **regional control plane** with multi-zonal node pools
- `regional = false` creates a **zonal control plane** in a single zone
- Affects `data.google_container_engine_versions.gke-version` provider location (`local.region` vs `local.zone`)

## Tooling Requirements & Versions

### Exact Version Pinning
**ALWAYS** match these versions (see `Dockerfile` and `versions.tf`):
- Terraform: `1.10.5`
- Google Provider: `6.28.0`
- kubectl: `1.34.6`
- gcloud CLI: `513.0.0`
- Kubernetes version prefix: Use format `"1.34"` (major.minor) for GKE auto-selection

### Docker Workflow (Recommended)
Build image: `docker build -t viya4-iac-gcp .`
Run commands with volume mounts for:
1. Service account keyfile: `--volume=$HOME/.service-account.json:/.service-account.json`
2. SSH keys: `--volume=$HOME/.ssh:/.ssh`
3. Workspace: `--volume=$(pwd):/workspace`

**Docker-specific settings**:
- `ENV TF_VAR_iac_tooling=docker` (set in Dockerfile)
- Kubeconfig path becomes `/workspace/${var.prefix}-gke-kubeconfig.conf` (see `locals.tf` line 42)

See `docs/user/DockerUsage.md` for complete examples.

## Configuration Patterns

### Required Variables (terraform.tfvars)
Start from `examples/sample-input.tfvars` or `examples/sample-input-ha.tfvars`:
- `prefix`: Must start with lowercase letter, alphanumeric + hyphens only (validated via regex in `variables.tf` line 8)
- `location`: GCP zone (e.g., `"us-east1-b"`) or region (e.g., `"us-east1"`)
- `project`: GCP project ID
- `service_account_keyfile`: Path to service account JSON file

**Prefix Validation Pattern**: `^[a-z][-0-9a-z]*[0-9a-z]$` - starts with lowercase letter, can contain hyphens but not at end.

### Network Access Control
**Default**: All resources are only accessible via authenticated GCP clients. To enable external access (kubectl, psql), set CIDR ranges:
- `default_public_access_cidrs`: Global default for all resources
- `cluster_endpoint_public_access_cidrs`: GKE API server access
- `vm_public_access_cidrs`: SSH access (port 22)
- `postgres_public_access_cidrs`: PostgreSQL access (port 5432)

**Fallback Logic** (`locals.tf` lines 20-23): Specific access CIDR variables fall back to `default_public_access_cidrs` if null.

### BYO (Bring Your Own) Resources
Support for existing VPC/subnets via:
- `vpc_name`: Existing VPC name
- `subnet_names`: Map with keys `gke`, `gke_pods_range_name`, `gke_services_range_name`, `misc`
- `nat_address_name`: Existing Cloud NAT IP address

**BYO Pattern**: If `length(var.subnet_names) == 0`, create new subnets. Otherwise, use existing (`locals.tf` lines 93-97).

See `docs/CONFIG-VARS.md` section "Use Existing" for details.

### PostgreSQL Configuration
PostgreSQL instances are created conditionally when `var.postgres_servers` is not null and non-empty.

**Database Flags**: All postgres instances get these required flags (`locals.tf` line 112):
- `max_prepared_transactions = 1024`
- `max_connections = 1024`

**Private IP Setup**: Requires PSA (Private Service Access) peering via `google_service_networking_connection.private_vpc_connection` (see `network.tf` lines 58-72).

## Testing Framework

### Go Terratest Structure
Tests use custom helper framework in `test/helpers/`:
- `TestCase` struct defines expected values with JSON path queries
- `Retriever` functions extract values from Terraform plans (3 types: `RetrieveFromRawPlan`, `RetrieveFromResourcePlannedValuesMap`, `RetrieveFromRawPlanResource`)
- `RunTests()` executes assertions against cached plans

**Example Pattern** (from `test/defaultplan/defaults_test.go`):
```go
tests := map[string]helpers.TestCase{
  "nameTest": {
    Expected:          fmt.Sprintf("%s-gke", variables["prefix"]),
    ResourceMapName:   "module.gke.google_container_cluster.primary",
    AttributeJsonPath: "{$.name}",
  },
}
helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
```

### Plan Caching
Tests use `helpers.GetDefaultPlan()` which caches Terraform plans to avoid repeated `terraform plan` calls (see `test/helpers/plan_cache.go`).

### Running Tests
```bash
cd test/defaultplan
go test -v -timeout 60m

# For NetApp-specific tests
cd test/nondefaultplan
go test -v -timeout 60m
```

## Key Commands

### Terraform Execution
```bash
# Via Docker (recommended)
docker run --rm --group-add root -v $(pwd):/workspace viya4-iac-gcp plan -var-file=/workspace/terraform.tfvars
docker run --rm --group-add root -v $(pwd):/workspace viya4-iac-gcp apply -var-file=/workspace/terraform.tfvars

# Direct execution
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### GKE Version Selection
Use **major.minor format only** for automatic patch version selection:
```bash
# In terraform.tfvars
kubernetes_version = "1.34"  # GCP selects latest 1.34.x-gke.N
```

Resolved via `data.google_container_engine_versions.gke-version` with `version_prefix` (see `main.tf` lines 94-98).

## Module Organization

### Root Modules
- `main.tf`: GKE cluster, Filestore, provider configs, build metadata
- `network.tf`: VPC, subnets, firewall rules, Cloud NAT, PSA peering for PostgreSQL
- `vms.tf`: Jump VM and NFS server VMs, storage endpoint calculation
- `locals.tf`: Complex logic for storage backends, zone selection, node pool configuration, CIDR fallbacks

### Child Modules
- `modules/google_netapp/`: NetApp Volumes provisioning with PSA peering, multi-zone detection
- `modules/google_vm/`: VM instance creation with cloud-init templates
- `modules/kubeconfig/`: Kubeconfig file generation for GKE cluster access
- `modules/network/`: VPC and subnet creation with secondary ranges

## File References & Authentication

### Service Account Keyfile
Variable `service_account_keyfile` can be:
- Absolute path to JSON file
- `null` when running on GCP VM with attached service account

Provider uses null-safe file reading:
```terraform
credentials = var.service_account_keyfile != null ? can(file(var.service_account_keyfile)) ? file(var.service_account_keyfile) : null : null
```

### SSH Keys
Variable `ssh_public_key` supports (`locals.tf` lines 25-28):
- Path to public key file (e.g., `"~/.ssh/id_rsa.pub"`)
- Direct key content string
- Used only when `create_jump_vm = true` or `storage_type = "standard"` with NFS VM

## Build Metadata
The project injects build metadata into the cluster via `kubernetes_config_map.sas_iac_buildinfo`:
- Git commit hash from `files/tools/iac_git_info.sh`
- Terraform version from `files/tools/iac_tooling_version.sh`
- Only created when `tf_enterprise_integration_enabled = false` (see `main.tf` lines 41-70)

## Common Pitfalls

1. **storage_type_backend Variable Confusion**: The `var.storage_type_backend` variable exists but is **completely ignored** by code. `locals.tf` line 34 overrides it. When users see `"storage_type_backend": "nfs"` in terraform.tfstate for `storage_type = "standard"`, this is **correct and expected** - it means NFS VM is deployed, not Google Filestore.
2. **Zone Mismatch**: NFS VM must be in same zone as GKE nodes for standard deployments
3. **CIDR Overlaps**: When using BYO subnets, ensure `gke_control_plane_subnet_cidr` (default `10.2.0.0/28`) doesn't overlap
4. **NetApp Subnet Size**: Requires minimum `/24` CIDR range (see `docs/CONFIG-VARS.md`)
5. **Filestore Not Deployed**: Despite condition in `main.tf` line 75, Google Filestore is never deployed because `local.storage_type_backend` is hardcoded to "nfs" for `storage_type = "standard"`
6. **Kubernetes Version Format**: Use `"1.34"` not `"1.34.6-gke.N"` for auto-selection
7. **Node Taint Format**: GKE uses `"NO_SCHEDULE"` but Terraform input uses `"NoSchedule"` (conversion in `locals.tf`)
8. **Initial Node Count**: Calculation targets ~6 initial nodes to avoid Ingress quota limit (see `locals.tf` line 46)

## Related Repositories
- **Deployment**: [viya4-deployment](https://github.com/sassoftware/viya4-deployment) - Deploys SAS Viya after infrastructure is provisioned
- **Documentation**: Official SAS Viya Operations docs referenced in README
