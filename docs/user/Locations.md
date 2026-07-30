## Resource Locations

Google Cloud resources are hosted in different data centers worldwide, divided into [Regions and Zones](https://cloud.google.com/compute/docs/regions-zones).

You control the location of your Viya4 IAC resources by setting the `location` variable to either a Region or a Zone.

The GKE control plane type is controlled by the `regional` variable.

- `regional = true` (default): a regional control plane is created in the resolved region.
- `regional = false`: a zonal control plane is created in the resolved zone.

The `location` variable controls node and VM placement and is also used to resolve region/zone values.

All other resources will be zonal.


If you choose a Region:

| Resource | Location |
| :--- | :--- |
| Cluster Control Plane | Regional in the specified Region when `regional=true`; zonal in the first Zone of the specified Region when `regional=false` |
| Default Node VMs | 1st Zone of the specified Region |
| GKE Cluster node VMs | 1st Zone of the specified Region |
| Jump VM | 1st Zone of the specified Region |
| NFS VM | 1st Zone of the specified Region |
| Postgres | Zonal in the 1st Zone the specified Region |

If you choose a Zone:

| Resource | Location |
| :--- | :--- |
| Cluster Control Plane | Regional in the Region of the specified Zone when `regional=true`; zonal in the specified Zone when `regional=false` |
| Default Node VMs | In the specified Zone |
| GKE Cluster node VMs | In the specified Zone |
| Jump VM | In the specified Zone |
| NFS VM | In the specified Zone |
| Postgres | Zonal in the specified Zone |
