resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.project_name}-public"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private" {
  name                     = "${var.project_name}-private"
  ip_cidr_range           = "10.10.1.0/24"
  region                  = var.region
  network                 = google_compute_network.vpc.id
  private_ip_google_access = true
}

resource "google_vpc_access_connector" "serverless" {
  name   = "${var.project_name}-conn"
  region = var.region
  subnet {
    name = google_compute_subnetwork.private.name
  }
}
