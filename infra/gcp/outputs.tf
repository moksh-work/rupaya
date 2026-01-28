output "cloud_run_url" {
  value       = google_cloud_run_v2_service.api.uri
  description = "Cloud Run public URL"
}

output "artifact_repo" {
  value       = google_artifact_registry_repository.backend.repository_id
  description = "Artifact Registry repository"
}

output "sql_public_ip" {
  value       = google_sql_database_instance.postgres.public_ip_address
  description = "Cloud SQL public IP"
}

output "redis_host" {
  value       = google_redis_instance.cache.host
  description = "Redis host"
}
