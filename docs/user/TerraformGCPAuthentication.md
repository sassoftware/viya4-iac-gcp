# Authenticating Terraform to access GCP

Terraform creates and destroys resources in the Google Cloud Platform on your behalf.
In order to do so, it needs to authenticate itself to GCP with the appropriate permissions.

This project uses a GCP Service Account to authenticate with GCP. You will need a Service Account with the appropriate permissions. You can use an existing Service Account, or preferably create a dedicated Service Account.

## Running Terraform outside Google Cloud

If you are running terraform outside of Google Cloud, generate a service account keyfile in JSON format and specify that keyfile either with the `GOOGLE_APPLICATION_CREDENTIALS` environment variable or with the [`service_account_keyfile` terraform variable](#Terraform-project-variables-to-authenticate-with-GCP).

## Running Terraform on Google Cloud

If you are running terraform on a VM in Google Cloud, you can [configure that VM instance to use your Service Account](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#using). This will allow Terraform to authenticate to Google Cloud without having to bake in a separate credential/authentication file. Ensure that the scope of the VM is set to or includes https://www.googleapis.com/auth/cloud-platform.


## Create a GCP Service Account

How to create a GCP Service Account: https://cloud.google.com/iam/docs/creating-managing-service-accounts

gcloud CLI Example:

```bash
SA_NAME="<my-service-account>"  #  <=== CHANGE
gcloud iam service-accounts create $SA_NAME  --description "Service Account for Terraform Viya4 Infrastructure" --display-name "$SA_NAME"
```

## Apply the necessary Roles to the Service Account

The Service Account will need the following [IAM roles](https://cloud.google.com/compute/docs/access/iam#predefinedroles):

| Role Name | Description | Use |
| :--- | :--- | :--- |
| `roles/cloudsql.admin` | Cloud SQL Admin | Needed if you create an [SQL Postgres instance](../CONFIG-VARS.md#postgres-servers) |
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

How to modify IAM access to GCP resources:  https://cloud.google.com/iam/docs/granting-changing-revoking-access

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

## Verify the necessary Roles have been applied to the Service Account

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

When running terraform on a workstation outside of the Google Cloud Platform, you persist the Service Account information to a JSON file, and then [specify that file when running terraform](#Terraform-project-variables-to-authenticate-with-GCP).

Managing key files using the Cloud Console: https://console.cloud.google.com/apis/credentials/serviceaccountkey

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
| service_account_keyfile | Filename of the Service Account JSON file. Alternatively, you can set the `GOOGLE_APPLICATION_CREDENTIAL` environment variable. Note that you do not need to set this variable when running on a GCP VM that is associated with the Service Account.  |
