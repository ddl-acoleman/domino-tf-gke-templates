# Domino GCP Infrastructure

This will create a cluster in GCP that Domino can be deployed with. If using this as a starting point for building out a GKE cluster, you will need to work on the networking portion of this, as the cluster it creates is wide-open.

There is also a template for provisioning a workstation that can do the actual install of Domino. See workstation.tf and workstation-startup-script-sh. Again, more work will need to be done around networking, if your cluster is not open to the public internet.

## Pre-Requisites

### Project Setup
- create the project
- assign billing 
- update terraform.tvars with project-id
- update main.tf and variables.tf to contain any additional config
- create a service account in the project that has permissions to provision this cluster
- create remote backend bucket in the project, grant the Terraform builder SA Storage Object Admin access to remote backend bucket
- update main.tf with the bucket name

### Enable GCP APIs

These are required APIs that aren't enabled by default

`gcloud services enable cloudresourcemanager.googleapis.com`

`gcloud services enable iamcredentials.googleapis.com`

`gcloud services enable file.googleapis.com`

`gcloud services enable cloudkms.googleapis.com`

## What does Terraform build

All required resources necessary for installing Domino on GCP, and a 
workstation VM that can be used to install Domino on the cluster.

This was built using Domino requirements which are defined at a high level here - https://admin.dominodatalab.com/en/4.1/requirements.html 

## How to build the environment

Terraform scripts to be executed using a service account that has the necessary permissions to create the resources in the target project.

 - Install Terraform
 - Download the service account key file mentioned above (if running outside of GCP environment)
 - Initialise - `terraform init`
 - Plan without applying - `terraform plan`
 - Apply Terraform scripts - `terraform apply`
 - Delete service account key file

## How to validate the environment 
Domino provides a validator that can be used to check whether the cluster meets their requirements. Follow this guide for running the validator - https://admin.dominodatalab.com/en/4.1/checker.html

## How to delete resources
Run - `terraform destroy`
Please note that certain resources aren't actually destroyed but instead are just removed from the terraform state file. For example - google_kms_key_ring. Running `terraform apply` after a destroy in this case will result in an error since Terraform will attempt to create an existing resource. Delete the resource manually to workaround this.

## Troubleshooting

### Keyring already exists
```Error: Error creating KeyRing: googleapi: Error 409: KeyRing <keyring name> already exists.```

Certain resources like google_kms_key_ring aren't actually destroyed but instead are just removed from the terraform state file. Running `terraform apply` after a destroy in this case will result in an error since Terraform will attempt to create an existing resource. Delete the resource manually to workaround this.