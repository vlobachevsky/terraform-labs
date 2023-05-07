locals {
  gcs_backet = "gs://${var.project_id}-bucket-1"
}

resource "google_compute_instance_template" "default" {
  name         = "autoscaling-instance01"
  machine_type = "e2-medium"

  disk {
    source_image = "debian-cloud/debian-10"
  }

  network_interface {
    network = "default"
  }

  metadata = {
    startup-script-url = "${local.gcs_backet}/startup.sh"
    gcs-bucket         = local.gcs_backet
  }
}