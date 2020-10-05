# Authenticating Terraform to access GCP

Terraform creates and destroys resources in the Google Cloud Platform on your behalf. In order to do so, it needs permission to do so and it needs to know which GCP Project to use.
This project used a GCP Service account. In short, you either already have or create a dedicated Service Account with the appropriate permissions. Then you create a JSON file that contains all the required information and keys associated with that Service Account. That JSON file is then passed into the Terraform project.

How to create GCP Service Account: https://cloud.google.com/iam/docs/creating-managing-service-accounts

Manage key files using the Cloud Console: https://console.cloud.google.com/apis/credentials/serviceaccountkey

