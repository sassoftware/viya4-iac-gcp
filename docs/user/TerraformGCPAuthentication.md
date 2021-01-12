# Authenticating Terraform to access GCP

Terraform creates and destroys resources in the Google Cloud Platform on your behalf. 
In order to do so, it needs to authenticate itself to GCP with the appropriate permissions.

This project uses a GCP Service Account to authenticate with GCP. You will need a Service Account with the appropriate permissions. You can use an existing Service Account, or preferably create a dedicated Service Account.

You then create a keyfile in JSON format with the Service Account information. Terraform uses that keyfile to authenticate to GCP 

## Create a GCP Service Account

How to create a GCP Service Account: https://cloud.google.com/iam/docs/creating-managing-service-accounts

GCLOUD CLI Example:

```bash
SA_NAME="<my-tf-gke>"  #  <=== CHANGE
gcloud iam service-accounts create $SA_NAME  --description "SA used for all terraform actions for gke" --display-name "$SA_NAME"

```


## Apply the necessary Roles to the Service Account

The Service Account will need the following [IAM roles](https://cloud.google.com/compute/docs/access/iam#predefinedroles):

| Role Name | Description | Use | 
| :--- | :--- | :---  |
| `roles/container.admin`| Kubernetes Engine Admin |
| `roles/compute.admin`|Compute Admin|
| `roles/compute.networkAdmin` | Compute Network Admin |
| `roles/iam.serviceAccountUser`| Service Account User |
| `roles/file.editor`| Cloud Filestore Editor | only needed for [`storage_type=="HA"`](../CONFIG-VARS.md#storage) |
| `roles/cloudsql.admin`| Cloud SQL Admin | only needed if you create an [SQL Postgres instance](../CONFIG-VARS.md#postgres) |

How modify IAM access to GCP resources:  https://cloud.google.com/iam/docs/granting-changing-revoking-access

GCLOUD CLI Example:
```bash
PROJECT="<my-project>"  # <== CHANGE
SA_NAME="<my-tf-gke>"   # <>== CHANGE
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com  --role roles/compute.networkAdmin
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com  --role roles/compute.admin  
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com  --role roles/container.admin  	
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com  --role roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com  --role roles/file.editor
gcloud projects add-iam-policy-binding $PROJECT --member serviceAccount:${SA_NAME}@${PROJECT}.iam.gserviceaccount.com  --role roles/cloudsql.admin

```



## Create the Service Account Keyfile

Manage key files using the Cloud Console: https://console.cloud.google.com/apis/credentials/serviceaccountkey

GCLOUD CLI Example:
```bash
PROJECT="<my-project>"  # <== CHANGE
SA_NAME="<my-tf-gke>"   # <>== CHANGE
gcloud iam service-accounts keys create ./${SA_NAME}-${PROJECT}-service-account.json --iam-account ${SA_NAME}@${PROJECT}.iam.gserviceaccount.com
```

## Terraform project variables to authenticate with GCP

As part of your [Terraform input variables](../../README.md#customize-input-values), set these values:

| Name | Description | 
| :--- | :--- |   
| project | The GCP Project to use | 
| service_account_keyfile | Filename of the Service Account JSON file | 

