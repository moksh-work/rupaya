resource "google_service_account" "run_sa" {
  account_id   = "${var.project_name}-run-sa"
  display_name = "${var.project_name} Cloud Run SA"
}

resource "google_project_iam_member" "secret_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_cloud_run_v2_service" "api" {
  name     = "${var.project_name}-api"
  location = var.region

  template {
    service_account = google_service_account.run_sa.email
    containers {
      image = "${google_artifact_registry_repository.backend.repository_url}/${var.project_name}-backend:${var.image_tag}"
      ports {
        container_port = var.container_port
      }
      env {
        name  = "PORT"
        value = tostring(var.container_port)
      }
      env { name = "NODE_ENV"  value = "production" }
      env { name = "FRONTEND_URL" value = var.frontend_url }
      env { name = "DB_HOST" value = google_sql_database_instance.postgres.public_ip_address }
      env { name = "DB_NAME" value = google_sql_database.app.name }
      env { name = "DB_USER" value = google_sql_user.app.name }
      env { name = "REDIS_URL" value = "redis://${google_redis_instance.cache.host}:6379" }
      env {
        name  = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.id
            version = "latest"
          }
        }
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.serverless.id
      egress    = "ALL_TRAFFIC"
    }
  }

  ingress = "INGRESS_TRAFFIC_ALL"
}

resource "google_cloud_run_v2_service_iam_binding" "invoker" {
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  members  = ["allUsers"]
}
