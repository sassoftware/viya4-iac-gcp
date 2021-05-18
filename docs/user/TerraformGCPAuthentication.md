# Authenticating Terraform to access GCP

Terraform creates and destroys resources in the Google Cloud Platform on your behalf.
In order to do so, it needs to authenticate itself to GCP with the appropriate permissions.

This project uses a GCP Service Account to authenticate with GCP. You will need a Service Account with the appropriate permissions. You can use an existing Service Account, or preferably create a dedicated Service Account.

You then create a keyfile in JSON format with the Service Account information. Terraform uses that keyfile to authenticate to GCP

## Create a GCP Service Account

How to create a GCP Service Account: https://cloud.google.com/iam/docs/creating-managing-service-accounts

gcloud CLI Example:

```bash
SA_NAME="<my-service-account>"  #  <=== CHANGE
gcloud iam service-accounts create $SA_NAME  --description "Service Account used Terraform Viya4 Infrastructure" --display-name "$SA_NAME"
```

## Apply the necessary Roles to the Service Account

The Service Account will need the following [IAM roles](https://cloud.google.com/compute/docs/access/iam#predefinedroles):

| Role Name | Description | Use |
| :--- | :--- | :--- |
| `roles/cloudsql.admin` | Cloud SQL Admin | Needed if you create an [SQL Postgres instance](../CONFIG-VARS.md#postgres) |
| `roles/compute.admin` | Compute Admin | Cluster creation |
| `roles/compute.networkAdmin` | Compute Network Admin | Network creation |
| `roles/compute.securityAdmin` | Compute Security Admin | Terraform Kubernetes Engine Module |
| `roles/compute.viewer` | Compute Viewer | Terraform Kubernetes Engine Module |
| `roles/container.admin` | Kubernetes Engine Admin | Cluster creation |
| `roles/container.clusterAdmin` | Kubernetes Engine Cluster Admin | Terraform Kubernetes Engine Module |
| `roles/container.developer` | Kubernetes Engine Developer | Cluster creation |
| `roles/file.editor` | Cloud Filestore Editor | Needed for [`storage_type=="HA"`](../CONFIG-VARS.md#storage) |
| `roles/iam.serviceAccountAdmin` | Service Account Admin | Terraform Kubernetes Engine Module |
| `roles/iam.serviceAccountUser` | Service Account User | Terraform Kubernetes Engine Module |
| `roles/resourcemanager.projectIamAdmin` | Project IAM Admin | Terraform Kubernetes Engine Module |

How modify IAM access to GCP resources:  https://cloud.google.com/iam/docs/granting-changing-revoking-access

gcloud CLI Example:
```bash
PROJECT="<my-project>"           # <== CHANGE
SA_NAME="<my-service-account>"   # <== CHANGE
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/cloudsql.admin
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/compute.admin
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/compute.networkAdmin
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/compute.securityAdmin
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/compute.viewer
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/container.admin
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/container.clusterAdmin
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/container.developer
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/file.editor
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/iam.serviceAccountAdmin
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com --role roles/resourcemanager.projectIamAdmin
```

## Verfiy the necessary Roles have been applied to the Service Account

Run the following command:

```bash
PROJECT="<my-project>"           # <== CHANGE
SA_NAME="<my-service-account>"   # <== CHANGE
gcloud projects get-iam-policy $PROJECT  \
--flatten="bindings[].members" \
--format='table(bindings.role)' \
--filter="bindings.members:$SA_NAME" | grep -v ROLE | sort -u
```

The output should look like this:

```bash
roles/cloudsql.admin
roles/compute.admin
roles/compute.networkAdmin
roles/compute.securityAdmin
roles/compute.viewer
roles/container.admin
roles/container.clusterAdmin
roles/container.developer
roles/file.editor
roles/iam.serviceAccountAdmin
roles/iam.serviceAccountUser
roles/resourcemanager.projectIamAdmin
```

## Create the Service Account Keyfile

Manage key files using the Cloud Console: https://console.cloud.google.com/apis/credentials/serviceaccountkey

gcloud CLI Example:

```bash
PROJECT="<my-project>"           # <== CHANGE
SA_NAME="<my-service-account>"   # <== CHANGE
SA_KEY_FILE="$HOME/.viya4-tf-gcp-service-account.json"
gcloud iam service-accounts keys create ${SA_KEY_FILE} --iam-account ${SA_NAME}@${PROJECT}.iam.gserviceaccount.com
chmod 500 ${SA_KEY_FILE} # secure the keyfile
```

## Terraform project variables to authenticate with GCP

As part of your [Terraform input variables](../../README.md#customize-input-values), set these values:

| Name | Description |
| :--- | :--- |
| project | The GCP Project to use |
| service_account_keyfile | Filename of the Service Account JSON file |
