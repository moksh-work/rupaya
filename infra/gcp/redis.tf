resource "google_redis_instance" "cache" {
  name           = "${var.project_name}-redis"
  tier           = "BASIC"
  memory_size_gb = var.redis_size_gb
  region         = var.region
  location_id    = var.region
  authorized_network = google_compute_network.vpc.id
}
