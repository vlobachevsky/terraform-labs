#!/bin/bash

gcloud auth application-default login
rm terraform.tfstate
terraform init
terraform plan