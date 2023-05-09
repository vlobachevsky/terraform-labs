This project provisions the following infrastructure in GCP:

- VPC with subnet
- GKE cluster with node pull


### Prerequisites

- gcloud installed https://cloud.google.com/sdk/docs/install-sdk
- KodeKloud GCP playground is running in browser incognito window 
- Application Default Credentials (ADC) to set up authentication will be used in contrast to JSON key file.

### Authenticate with gcloud

Run the command to authenticate with gcloud:

```
gcloud auth application-default login
```
Copy and open auth url in the incognito window
Select account created for this playground

### Configure Terraform provider

Add your Project ID to `terraform.tfvars`

### Run Terraform

Delete `terraform.tfstate` if exists in the project folder
- `terraform init` (switch on VPN for this step)
- `terraform plan`
- `terraform apply`

### Using setup.sh script

Alternatively, run `setup.sh` script that does the tree steps above except `terraform apply`. Also, make sure to switch VPN on before running the script and switch it off 
before running `terraform apply`.

### Configure kubectl

Refresh current auth token:

```
gcloud auth login
gcloud config set project PROJECT_ID
```

Choose option `[1] Re-initialize this configuration [default] with new settings`, then choose your current playground account and etc.

Run the following command to retrieve the access credentials for your cluster and automatically configure:

```
gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --zone us-west1-a
```
