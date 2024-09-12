## Resource Locations

Google Cloud resources are hosted in different data centers worldwide, divided into [Regions and Zones](https://cloud.google.com/compute/docs/regions-zones).

You control the location of your Viya4 IAC resources by setting the `location` variable to either a Region or a Zone.

In each case, a regional Cluster will be created, that is, the cluster control plane will be replicated in all zones in the region.

All other resources will be zonal.


If you choose a Region:

| Resource | Location |
| :--- | :--- |
| Cluster Control Plane | Regional in the specified Region |
| Default Node VMs | 1st Zone of the specified Region |
| GKE Cluster node VMs | 1st Zone of the specified Region |
| Jump VM | 1st Zone of the specified Region |
| NFS VM | 1st Zone of the specified Region |
| Postgres | Zonal in the 1st Zone the specified Region |

If you chose a Zone:

| Resource | Location |
| :--- | :--- |
| Cluster Control Plane | Regional in the Region of the specified Zone |
| Default Node VMs | In the specified Zone |
| GKE Cluster node VMs | In the specified Zone |
| Jump VM | In the specified Zone |
| NFS VM | In the specified Zone |
| Postgres | Zonal in the specified Zone |
