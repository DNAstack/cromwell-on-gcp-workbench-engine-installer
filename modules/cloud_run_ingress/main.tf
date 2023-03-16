terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.55.0"
    }
  }
}

resource "google_project_service" "cloud_run" {
  project = var.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

resource "google_service_account" "cloud_run_account" {
  project = var.project_id
  account_id = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
}

# Start nginx conf setup
resource "google_project_service" "cloud_secrets" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_secret_manager_secret" "nginx_conf" {
  project   = var.project_id
  secret_id = "nginx_conf"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [google_project_service.cloud_secrets]
}

resource "google_secret_manager_secret_version" "nginx_conf_version" {
  secret      = google_secret_manager_secret.nginx_conf.id
  secret_data = templatefile("${path.module}/reverse_proxy.conf", {
    ip_address : var.cromwell_ip,
    port : "8000"
  })
}

data "google_iam_policy" "cloud_run_policy" {
  binding {
    role    = "roles/secretmanager.secretAccessor"
    members = ["serviceAccount:${google_service_account.cloud_run_account.email}"]
  }
}

resource "google_secret_manager_secret_iam_policy" "cloud_run_secret_access" {
  project     = var.project_id
  secret_id   = google_secret_manager_secret.nginx_conf.secret_id
  policy_data = data.google_iam_policy.cloud_run_policy.policy_data
}
# End nginx conf setup

resource "google_project_service" "vpc_access" {
  project = var.project_id
  service = "vpcaccess.googleapis.com"

  disable_on_destroy = false
}

resource "google_vpc_access_connector" "cloud_run_vpc_connector" {
  project       = var.project_id
  region        = var.region
  name          = "cloud-run-vpc-connector"
  network       = var.cromwell_network_self_link
  ip_cidr_range = "10.3.0.0/28"

  depends_on = [google_project_service.vpc_access]
}

resource "google_cloud_run_service" "default" {
  name     = "cromwell-ingress"
  location = var.region
  project  = var.project_id

  template {
    spec {
      service_account_name = google_service_account.cloud_run_account.email

      containers {
        image = "nginx:1.23"
        ports {
          container_port = 80
        }
        volume_mounts {
          name       = "default_conf"
          mount_path = "/etc/nginx/conf.d/"
        }
        resources {
          limits = {
            # Picked arbitrarily to have some limit
            # If you change this, set the request to the same size (it is not good to have "burstable" memory)
            memory = "1G"
            cpu = "2000m"
          }
          requests = {
            memory = "1G"
            cpu = "500m"
          }
        }
      }

      volumes {
        name = "default_conf"
        secret {
          secret_name = google_secret_manager_secret.nginx_conf.secret_id
          items {
            key  = "latest"
            path = "default.conf"
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = "1"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.cloud_run_vpc_connector.name
        "run.googleapis.com/vpc-access-egress"    = "all-traffic"
        # Attempt to force updates when secret changes
        "secret-hash"                             = sha512(google_secret_manager_secret_version.nginx_conf_version.secret_data)
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.cloud_run, google_secret_manager_secret_version.nginx_conf_version]
}

data "google_iam_policy" "allow_generated_service_account" {
  binding {
    role    = "roles/run.invoker"
    members = [
      "serviceAccount:${var.generated_service_account_email}"
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "allow_generated_service_account" {
  service  = google_cloud_run_service.default.name
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project

  policy_data = data.google_iam_policy.allow_generated_service_account.policy_data
}