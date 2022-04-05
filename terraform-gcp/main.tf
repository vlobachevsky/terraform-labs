terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.12.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance_template" "default" {
  name         = "autoscaling-instance01"
  machine_type = "e2-medium"

  disk {
    source_image = "debian-cloud/debian-9"
  }

  network_interface {
    network = "default"
  }

  metadata = {
    startup-script-url = "${local.gcs_backet}/startup.sh"
    gcs-bucket         = local.gcs_backet
  }
}
