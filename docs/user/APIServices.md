## API Services

Make sure your Google Cloud Project has at least the following API Services enabled:

| API  Service Name | Description/Link | Use |
| :--- | :--- | :---  |
| `container.googleapis.com` | [Kubernetes Engine API](https://console.cloud.google.com/apis/library/container.googleapis.com) ||
| `compute.googleapis.com`| [Compute Engine API](https://console.cloud.google.com/apis/library/compute.googleapis.com) ||
| `file.googleapis.com` | [Cloud Filestore API](https://console.cloud.google.com/apis/library/file.googleapis.com) | Only needed for `storage_type="ha"` |
| `sqladmin.googleapis.com`| [Cloud SQL Admin API](https://console.cloud.google.com/apis/library/sqladmin.googleapis.com) | Only needed when creating an [SQL Postgres instance](../CONFIG-VARS.md#postgres)
| `servicenetworking.googleapis.com`| [Service Networking API](https://console.cloud.google.com/apis/library/servicenetworking.googleapis.com) | Only needed when creating an [SQL Postgres instance](../CONFIG-VARS.md#postgres)
| `cloudresourcemanager.googleapis.com`| [Cloud Resource Manager API](https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com) | only needed if you create an [SQL Postgres instance](../CONFIG-VARS.md#postgres) |

Further detail on [enabling API Services](https://cloud.google.com/apis/docs/getting-started#enabling_apis).
