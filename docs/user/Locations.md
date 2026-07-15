## Resource Locations

Google Cloud resources are hosted in different data centers worldwide, divided into [Regions and Zones](https://cloud.google.com/compute/docs/regions-zones).

Resource placement behavior is controlled by both `location` and `regional`:

- `location`: accepts either a Region (for example, `us-east1`) or a Zone (for example, `us-east1-b`).
- `regional`: controls whether the GKE control plane is regional (`true`) or zonal (`false`).

When `location` is a Region, zonal resources default to the first available zone in that region.

Control plane behavior:

| `regional` | GKE Control Plane |
| :--- | :--- |
| `true` | Regional control plane in the resolved Region |
| `false` | Zonal control plane in the resolved Zone |

If you choose a Region:

| Resource | Location |
| :--- | :--- |
| Cluster Control Plane | Regional if `regional=true`; zonal (in 1st zone) if `regional=false` |
| Default Node VMs | 1st Zone of the specified Region |
| GKE Cluster node VMs | 1st Zone by default; can span zones when node pool location variables are set |
| Jump VM | 1st Zone of the specified Region |
| NFS VM | 1st Zone of the specified Region |
| Postgres | Zonal in the 1st Zone of the specified Region |

If you chose a Zone:

| Resource | Location |
| :--- | :--- |
| Cluster Control Plane | Regional if `regional=true`; zonal in the specified Zone if `regional=false` |
| Default Node VMs | In the specified Zone |
| GKE Cluster node VMs | In the specified Zone by default; can span zones when node pool location variables are set |
| Jump VM | In the specified Zone |
| NFS VM | In the specified Zone |
| Postgres | Zonal in the specified Zone |

Notes:

- Current default is `regional=true`, which creates a regional control plane unless you explicitly set `regional=false`.
- Worker node placement is controlled by `default_nodepool_locations`, `nodepools_locations`, and `node_pools.<name>.node_locations`.
- With current defaults, a deployment uses a regional control plane and single-zone worker nodes.
