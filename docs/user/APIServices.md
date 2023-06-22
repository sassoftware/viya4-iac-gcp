## API Services

Make sure your Google Cloud Project has at least the following API Services enabled:

| API  Service Name | Description/Link | Use |
| :--- | :--- | :---  |
| `container.googleapis.com` | [Kubernetes Engine API](https://console.cloud.google.com/apis/library/container.googleapis.com) ||
| `compute.googleapis.com`| [Compute Engine API](https://console.cloud.google.com/apis/library/compute.googleapis.com) ||
| `file.googleapis.com` | [Cloud Filestore API](https://console.cloud.google.com/apis/library/file.googleapis.com) | Needed for `storage_type="ha"` |
| `sqladmin.googleapis.com`| [Cloud SQL Admin API](https://console.cloud.google.com/apis/library/sqladmin.googleapis.com) | Needed when creating an [SQL Postgres instance](../CONFIG-VARS.md#postgres-servers) |
| `servicenetworking.googleapis.com`| [Service Networking API](https://console.cloud.google.com/apis/library/servicenetworking.googleapis.com) | Needed when creating an [SQL Postgres instance](../CONFIG-VARS.md#postgres-servers) |
| `cloudresourcemanager.googleapis.com`| [Cloud Resource Manager API](https://console.cloud.google.com/apis/library/cloudresourcemanager.googleapis.com) | Needed if you create an [SQL Postgres instance](../CONFIG-VARS.md#postgres-servers) |
| `containerregistry.googleapis.com` | [Google Container Registry](https://console.cloud.google.com/apis/library/containerregistry.googleapis.com) | Needed when using GCR to store and access deployment artifacts |
| `artifactregistry.googleapis.com` | [Google Artifact Registry](https://console.cloud.google.com/apis/library/artifactregistry.googleapis.com) | Needed when using GAR to store and access deployment artifacts |

Further detail on [enabling API Services](https://cloud.google.com/apis/docs/getting-started#enabling_apis).
