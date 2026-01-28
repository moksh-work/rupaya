resource "google_sql_database_instance" "postgres" {
  name             = "${var.project_name}-postgres"
  database_version = var.db_version
  region           = var.region

  settings {
    tier = var.db_tier

    ip_configuration {
      ipv4_enabled    = true
      require_ssl     = false
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }
  }
}

resource "google_sql_user" "app" {
  name     = var.project_name
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
}

resource "google_sql_database" "app" {
  name     = var.project_name
  instance = google_sql_database_instance.postgres.name
}
