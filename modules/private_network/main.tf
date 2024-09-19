terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.2.0"
    }
  }
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "networking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"

  disable_on_destroy = false
}

resource "google_compute_network" "network" {
  name                    = "${var.base_name}-network"
  project                 = var.project_id
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute, google_project_service.networking]
}

resource "google_compute_subnetwork" "subnet" {
  project       = var.project_id
  network       = google_compute_network.network.id
  region        = var.region
  ip_cidr_range = var.ip_cidr_range
  name          = "${var.base_name}-subnet"
}

resource "google_compute_router" "internet_router" {
  project = var.project_id
  region  = var.region

  name    = "${var.base_name}-router"
  network = google_compute_network.network.name
}

resource "google_compute_router_nat" "internet_nat" {
  project = var.project_id

  name                               = "${var.base_name}-nat"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  router                             = google_compute_router.internet_router.name

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
