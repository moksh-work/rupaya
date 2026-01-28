resource "google_artifact_registry_repository" "backend" {
  location      = var.region
  repository_id = "${var.project_name}-backend"
  description   = "Backend container images"
  format        = "DOCKER"
}
