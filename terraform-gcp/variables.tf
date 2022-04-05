variable "project" { }

variable "credentials_file" { }

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

locals {
  gcs_backet = "gs://${var.project}-bucket-1"  
}