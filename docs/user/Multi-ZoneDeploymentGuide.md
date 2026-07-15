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

- **GKE worker node placement** via `default_nodepool_locations` and `nodepools_locations`
- **GKE control plane mode** via `regional`
- **Google NetApp Volumes DNS abstraction** for zone-redundant storage via `enable_netapp_dns`

Multi-zone worker placement and NetApp DNS behavior are opt-in. The GKE control plane defaults to regional unless you explicitly set `regional = false`.

### What Gets Protected

| Component | Multizone Behavior | Outcome |
| :--- | :--- | :--- |
| GKE node pools | Nodes spread across multiple zones | Pods can reschedule if a zone fails |
| GKE control plane | Regional control plane when `regional = true` | Better control-plane resilience |
| Google NetApp Volumes | Zone-redundant storage with optional DNS abstraction | Stable endpoint for failover scenarios |
| Shared storage endpoint | DNS hostname when enabled | Avoids depending on a static IP |

### Multizone Rules in This Repository

The repository treats a deployment as multizone when `default_nodepool_locations` contains more than one zone.

Relevant implementation details:

- `modules/google_netapp/locals.tf` sets `local.is_multizone = length(split(",", var.default_nodepool_locations)) > 1`
- `modules/google_netapp/main.tf` creates DNS resources only when `enable_netapp_dns = true` **and** `local.is_multizone = true`
- `vms.tf` uses the NetApp module `endpoint` output for the shared storage endpoint
- `outputs.tf` exposes `rwx_filestore_endpoint` as a DNS hostname when DNS abstraction is enabled

## GKE Multi-Zone Configuration

Enable multi-zone GKE worker placement by setting the node pool zone inputs. Use `regional` only if you want to override the default regional control plane behavior.

### Configuration Variables

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | --- |
| `regional` | Use a regional or zonal GKE control plane | bool | `true` | Set `false` for a zonal control plane |
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
- `regional = true` keeps the control plane regional and is already the default
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
- `netapp_service_level = "FLEX"` is required for zone-redundant NetApp storage pools

## Complete Multi-Zone Example

A complete starter example is available in:

- `examples/sample-input-multizone.tfvars`

That example includes:

- Regional GKE control plane configuration
- Multi-zone node placement
- Google NetApp Volumes configuration
- DNS abstraction for the shared storage endpoint

## Deployment Scenarios

### Scenario 1: Multizone GKE Only

Use this when you want GKE nodes spread across zones but do not need NetApp DNS abstraction.

Suggested settings:

- `regional = true`
- `default_nodepool_locations` with 2+ zones
- `enable_netapp_dns = false`

### Scenario 2: Full Multizone with NetApp DNS

Use this when you want multizone GKE plus a stable storage endpoint for zone-redundant NetApp volumes.

Suggested settings:

- `regional = true`
- `default_nodepool_locations` with 2+ zones
- `storage_type = "ha"`
- `netapp_service_level = "FLEX"`
- `enable_netapp_dns = true`

## Limitations Summary

- The DNS abstraction is only created when the deployment is multizone
- `netapp_service_level` must be `FLEX` for zone-redundant storage pools
- The feature provides a stable endpoint, but application failover still requires operational recovery steps
- If you use single-zone node placement, the DNS abstraction is not created

## Backward Compatibility

Existing single-zone worker-node deployments continue to work with the current defaults.

- `regional` defaults to `true`
- `default_nodepool_locations` defaults to an empty string
- `nodepools_locations` defaults to an empty string
- `enable_netapp_dns` defaults to `false`

## Default Values

### GKE Defaults

```hcl
regional = true
default_nodepool_locations = ""
nodepools_locations = ""
```

With these defaults, the control plane is regional and worker nodes stay in a single zone unless node pool location variables are set.

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
3. Use `storage_type = "ha"` only when you need Google NetApp Volumes.
4. Set `netapp_service_level = "FLEX"` for zone-redundant storage pools.
5. Enable `enable_netapp_dns = true` only for multizone deployments.
6. Keep `netapp_dns_record_ttl` at a value that balances failover speed and DNS stability.

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
