# Multi-Zone Deployment Guide

## Table of Contents

- [Overview](#overview)
- [GKE Multi-Zone Configuration](#gke-multi-zone-configuration)
	- [Configuration Variables](#configuration-variables)
	- [Usage Example](#usage-example)
	- [Validation](#validation)
- [Google NetApp Volumes Cross-Zone Replication](#google-netapp-volumes-cross-zone-replication)
	- [Configuration Variables](#configuration-variables-1)
	- [Usage Example](#usage-example-1)
	- [DNS-Based Failover Resilience](#dns-based-failover-resilience)
	- [Validation](#validation-1)
- [Complete Multi-Zone Example](#complete-multi-zone-example)
- [Deployment Scenarios](#deployment-scenarios)
- [RWO Block Storage in Multi-Zone Deployments](#rwo-block-storage-in-multi-zone-deployments)
	- [Expected Scheduling Delays for Stateful Workloads During Initial Deployment](#expected-scheduling-delays-for-stateful-workloads-during-initial-deployment)
- [Limitations Summary](#limitations-summary)
- [Backward Compatibility](#backward-compatibility)
- [Default Values](#default-values)
- [Cost Considerations](#cost-considerations)
- [Recommended Architecture](#recommended-architecture)
- [Best Practices for GCP Multi-Zone](#best-practices-for-gcp-multi-zone)
- [References](#references)

## Overview

This guide describes how to deploy SAS Viya on Google Cloud Platform (GCP) in a multi-zone configuration using the current `viya4-iac-gcp` implementation.

The GCP multizone model in this repository is built around three pieces:

- **GKE node placement** via `default_nodepool_locations` and `nodepools_locations`
- **Regional control plane** via `regional`
- **Google NetApp Volumes DNS abstraction** for zone-redundant storage via `enable_netapp_dns`

All multizone behavior in this repository is opt-in and uses safe defaults for single-zone deployments.

If you deploy an external PostgreSQL instance with this IaC for a multi-zone SAS Viya environment, configure that Cloud SQL instance for high availability by setting `availability_type = "REGIONAL"`. The default PostgreSQL configuration is `ZONAL`, which does not provide multi-zone database resilience.

### What Gets Protected

| Component | Multizone Behavior | Outcome |
| :--- | :--- | :--- |
| GKE node pools | Nodes spread across multiple zones | Pods can reschedule if a zone fails |
| GKE control plane | Regional control plane when `regional = true` | Better control-plane resilience |
| Google NetApp Volumes (RWX) | Zone-redundant storage with optional DNS abstraction | Stable endpoint for failover scenarios |
| Shared storage endpoint | DNS hostname when enabled | Avoids depending on a static IP |
| RWO block storage (RabbitMQ / Crunchy) | Zonal Persistent Disks by default (`pd-ssd-mq`, `pd-ssd-pg`) | Volumes are created in a single zone; not zone-redundant. See [RWO Block Storage in Multi-Zone Deployments](#rwo-block-storage-in-multi-zone-deployments) below. |

### Multizone Rules in This Repository

The repository treats a deployment as multizone when `default_nodepool_locations` contains more than one zone.

Relevant implementation details:

- `modules/google_netapp/locals.tf` sets `local.is_multizone = length(split(",", var.default_nodepool_locations)) > 1`
- `modules/google_netapp/main.tf` creates DNS resources only when `enable_netapp_dns = true` **and** `local.is_multizone = true`
- `vms.tf` uses the NetApp module `endpoint` output for the shared storage endpoint
- `outputs.tf` exposes `rwx_filestore_endpoint` as a DNS hostname when DNS abstraction is enabled

## GKE Multi-Zone Configuration

Enable multizone GKE placement by setting the control plane and node pool zone inputs.

### Configuration Variables

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | --- |
| `regional` | Use a regional or zonal GKE control plane | bool | `false` | Set `true` for a regional control plane |
| `default_nodepool_locations` | Comma-separated list of zones for the default node pool | string | `""` | Use 2 or more zones to enable multizone behavior |
| `nodepools_locations` | Comma-separated list of zones for additional node pools | string | `""` | Optional global fallback for additional node pools |

### Usage Example

```hcl
regional = true

default_nodepool_locations = "us-east1-b,us-east1-c,us-east1-d"
nodepools_locations        = "us-east1-b,us-east1-c,us-east1-d"
```

### Validation

The configuration is considered multizone when `default_nodepool_locations` contains multiple zones.

Validation expectations:

- `default_nodepool_locations` must contain at least two zones for multizone behavior
- `regional = true` is recommended for a regional control plane in multizone deployments
- Additional node pools may use `nodepools_locations` as a global fallback

## Google NetApp Volumes Cross-Zone Replication

When `storage_type = "ha"`, the repository provisions Google NetApp Volumes for RWX storage. When `enable_netapp_dns = true` and multizone is detected, the module creates a Private Cloud DNS zone and A record for the shared storage endpoint.

### Configuration Variables

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | --- |
| `storage_type` | Storage type used by the deployment | string | `standard` | Set `ha` to provision Google NetApp Volumes |
| `netapp_service_level` | NetApp storage pool service level | string | `PREMIUM` | Use `FLEX` for zone-redundant pools |
| `enable_netapp_dns` | Enable Private DNS zone and A record for the NetApp endpoint | bool | `false` | Only applies when the deployment is multizone |
| `netapp_dns_zone_name` | Private DNS zone name for NetApp | string | `netapp-private.internal` | Used only when `enable_netapp_dns = true` |
| `netapp_dns_hostname` | Hostname used for the NetApp endpoint | string | `netapp-volume` | Used only when `enable_netapp_dns = true` |
| `netapp_dns_record_ttl` | TTL for the DNS A record | number | `300` | Used only when `enable_netapp_dns = true`; valid range is `60` to `86400` |

### Usage Example

```hcl
storage_type         = "ha"
netapp_service_level = "FLEX"

enable_netapp_dns     = true
netapp_dns_zone_name  = "netapp.internal"
netapp_dns_hostname   = "netapp-volume"
netapp_dns_record_ttl = 300
```

### DNS-Based Failover Resilience

When `enable_netapp_dns = true` and the deployment is multizone:

- A private Cloud DNS zone is created
- An A record is created for the NetApp endpoint
- `rwx_filestore_endpoint` returns a DNS hostname instead of a raw IP
- `netapp_dns_record_ttl` controls the DNS TTL

This is intended to simplify failover handling for zone-redundant NetApp deployments.

### Validation

The repository validates the following multizone behavior:

- `enable_netapp_dns` only creates DNS resources when multizone is detected
- `netapp_dns_hostname` must be a valid DNS hostname
- `netapp_dns_record_ttl` must be between `60` and `86400`
- `netapp_service_level = "FLEX"` is required only for zone-redundant NetApp storage pools

## Complete Multi-Zone Example

A complete starter example is available in:

- `examples/sample-input-multizone.tfvars`

That example includes:

- Regional GKE control plane configuration
- Multi-zone node placement
- External PostgreSQL configured for Cloud SQL high availability with `availability_type = "REGIONAL"`
- Google NetApp Volumes configuration
- DNS abstraction for the shared storage endpoint

## Deployment Scenarios

### Scenario 1: Multizone GKE Only

Use this when you want GKE nodes spread across zones but do not need NetApp DNS abstraction.

Suggested settings:

- `regional = true`
- `default_nodepool_locations` with 2+ zones
- `availability_type = "REGIONAL"` when provisioning external PostgreSQL with this IaC
- `enable_netapp_dns = false`

### Scenario 2: Full Multizone with NetApp DNS

Use this when you want multizone GKE plus a stable storage endpoint for zone-redundant NetApp volumes.

Suggested settings:

- `regional = true`
- `default_nodepool_locations` with 2+ zones
- `availability_type = "REGIONAL"` when provisioning external PostgreSQL with this IaC
- `storage_type = "ha"`
- `netapp_service_level = "FLEX"`
- `enable_netapp_dns = true`

## RWO Block Storage in Multi-Zone Deployments

The default GCP StorageClasses for RabbitMQ (`pd-ssd-mq`) and Crunchy Postgres (`pd-ssd-pg`) provision **zonal** Persistent Disks. These classes use `volumeBindingMode: WaitForFirstConsumer`, which means the disk is created in the same zone as the consuming pod.

In a multi-zone GKE deployment this has the following implications:

- If a pod is rescheduled to a **different zone**, it cannot attach to the existing zonal PD.
- Application-level HA (e.g., RabbitMQ mirrored queues, Crunchy Postgres replicas) handles cross-zone resilience at the application layer, not the storage layer.
- GCP supports [Regional Persistent Disks](https://cloud.google.com/compute/docs/disks/regional-persistent-disk) that replicate data across two zones. These are **not** used by default in the current StorageClass definitions.

If your deployment requires zone-redundant RWO block storage, you can supply your own Regional PD StorageClasses by setting `V4_CFG_MANAGE_STORAGE = false` in viya4-deployment and pre-creating StorageClasses with `replication-type: regional-pd` in their parameters. Refer to the [GCP Regional PD documentation](https://cloud.google.com/compute/docs/disks/regional-persistent-disk) for details.

### Expected Scheduling Delays for Stateful Workloads During Initial Deployment

During the initial startup of a GCP multi-zone Viya deployment, stateful workloads such as Consul and RabbitMQ may appear in `Pending` state for several minutes. This is **expected behavior**, not a deployment failure.

**Why this happens:**

When `volumeBindingMode: WaitForFirstConsumer` is in effect, the scheduler must reconcile several constraints simultaneously:

- **PersistentVolume node affinity** : once a zonal PD is provisioned the PV gains a node-affinity rule that pins it to the provisioning zone
- **Topology spread constraints** : viya4-deployment enforces `maxSkew: 1` across zones for StatefulSets when `V4_CFG_MULTI_ZONE_ENABLED: true`
- **Node selectors and taints** : stateful workloads target labeled stateful node pools via `workload.sas.com/class=stateful`

During initial provisioning, before all PVs are created, the scheduler is evaluating these constraints in a partially-provisioned state. The result is transient `Pending` events that resolve once GKE completes disk provisioning and zone placement stabilizes.

**Example scheduler event (expected during startup):**

```
0/16 nodes are available:
1 node(s) didn't match PersistentVolume's node affinity,
2 node(s) didn't match pod topology spread constraints,
4 node(s) didn't match Pod's node affinity/selector,
9 node(s) had untolerated taint(s).
Preemption is not helpful for scheduling.
```

**How to distinguish expected delay from a real problem:**

| Signal | Expected Delay | Investigate Further |
| :--- | :--- | :--- |
| Duration of `Pending` state | Resolves within 5–15 minutes | Persists beyond 30 minutes |
| Scheduler event message | PV node affinity + topology spread constraints | Insufficient CPU/memory, image pull errors |
| Pod count | Only 1-2 pods Pending at a time | All replicas Pending simultaneously |
| Events after `kubectl describe pod` | Node affinity / topology constraint messages | `FailedScheduling` with unrelated reasons |

**Checking pod scheduling events:**

```bash
kubectl describe pod <pending-pod-name> -n <viya-namespace>
# Look for the Events section "didn't match PersistentVolume's node affinity"
# and "didn't match pod topology spread constraints" are normal during startup.
```

If pods remain `Pending` for more than 30 minutes, or if events indicate resource exhaustion rather than placement constraints, investigate further.

## Limitations Summary

- The DNS abstraction is only created when the deployment is multizone
- `netapp_service_level` must be `FLEX` only when you need zone-redundant storage pools
- The feature provides a stable endpoint, but application failover still requires operational recovery steps
- If you use single-zone node placement, the DNS abstraction is not created
- Default RWO StorageClasses (`pd-ssd-mq`, `pd-ssd-pg`) use zonal Persistent Disks and are not zone-redundant
- Stateful workloads may show transient `Pending` scheduling events during initial GCP multi-zone deployment; this is expected and self-resolving (see [Expected Scheduling Delays](#expected-scheduling-delays-for-stateful-workloads-during-initial-deployment))

## Backward Compatibility

Existing single-zone deployments continue to work with the current defaults.

- `regional` defaults to `false`
- `default_nodepool_locations` defaults to an empty string
- `nodepools_locations` defaults to an empty string
- `enable_netapp_dns` defaults to `false`

## Default Values

### GKE Defaults (Single-Zone Behavior)

```hcl
regional = false
default_nodepool_locations = ""
nodepools_locations = ""
```

### NetApp Defaults (DNS Disabled)

```hcl
storage_type         = "standard"
netapp_service_level = "PREMIUM"
enable_netapp_dns    = false
netapp_dns_zone_name = "netapp-private.internal"
netapp_dns_hostname  = "netapp-volume"
netapp_dns_record_ttl = 300
```

## Cost Considerations

Enabling multizone GKE and NetApp DNS abstraction can increase infrastructure cost:

| Area | Cost Impact | Notes |
| :--- | :--- | :--- |
| Regional GKE control plane | Low to moderate | Depends on cluster size and node placement |
| Multi-zone node pools | Moderate | More nodes may be distributed across zones |
| NetApp `FLEX` storage | Higher than single-zone setups | Required for zone-redundant NetApp pools |
| Cloud DNS | Low | Small incremental cost for zone and A record |

## Recommended Architecture

For production multizone deployments, use both GKE multizone placement and NetApp DNS abstraction together:

```text
Zone A                         Zone B
├─ GKE nodes                   ├─ GKE nodes
├─ Application pods            ├─ Application pods
├─ NetApp primary endpoint     ├─ NetApp DNS-targeted failover
└─ Regional control plane       └─ Shared storage endpoint
```

When the NetApp DNS abstraction is enabled, application workloads reference a stable hostname via `rwx_filestore_endpoint` instead of a zone-specific IP.

## Best Practices for GCP Multi-Zone

1. Use `regional = true` when deploying across multiple zones.
2. Set `default_nodepool_locations` with at least two zones.
3. If provisioning external PostgreSQL with this IaC, set `availability_type = "REGIONAL"`.
4. Use `storage_type = "ha"` only when you need Google NetApp Volumes.
5. Set `netapp_service_level = "FLEX"` for zone-redundant storage pools.
6. Enable `enable_netapp_dns = true` only for multizone deployments.
7. Keep `netapp_dns_record_ttl` at a value that balances failover speed and DNS stability.
8. Be aware that default RWO block StorageClasses (`pd-ssd-mq`, `pd-ssd-pg`) use zonal Persistent Disks. If zone-redundant RWO storage is needed, create custom Regional PD StorageClasses and set `V4_CFG_MANAGE_STORAGE = false`.
9. Expect stateful workloads (Consul, RabbitMQ) to show brief `Pending` scheduling events during initial deployment. This is normal — pods resolve within 5–15 minutes as PVs are provisioned and zone placement stabilizes.

## References

### Related GCP Documentation

- [CONFIG-VARS.md](../CONFIG-VARS.md) - All configuration variables
- [APIServices.md](APIServices.md) - Required GCP APIs
- [TerraformGCPAuthentication.md](TerraformGCPAuthentication.md) - Required IAM roles

### Related Configuration Files

- `examples/sample-input-multizone.tfvars` - Example multizone configuration
- `modules/google_netapp/main.tf` - DNS zone and record creation
- `modules/google_netapp/outputs.tf` - NetApp endpoint outputs
- `vms.tf` - Shared storage endpoint selection
