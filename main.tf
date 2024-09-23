terraform {
  required_version = "~> 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "google" {
  region = var.region
  zone   = var.zone
}

# Project setup
resource "google_project" "project" {
  name            = var.deployment_project_name
  project_id      = var.deployment_project_id
  folder_id       = var.deployment_project_folder_id
  billing_account = var.deployment_project_billing_account

  auto_create_network = "false"
  labels = var.deployment_project_labels
}

data "google_client_openid_userinfo" "provider_credentials" {}

resource "google_project_iam_member" "storage_admin_role" {
  project = google_project.project.project_id
  role    = "roles/storage.admin"
  member  = "${can(regex(".+\\.iam\\.gserviceaccount\\.com", data.google_client_openid_userinfo.provider_credentials.email)) ? "serviceAccount" : "user" }:${data.google_client_openid_userinfo.provider_credentials.email}"
}

resource "google_service_account" "generated_service_account" {
  account_id   = "generated-service-account"
  display_name = "Generated Service Account"
  description  = "An generated identity for accessing the Cloud Run service in this project"
  project      = google_project.project.project_id
}

resource "google_service_account_key" "generated_service_account_key" {
  service_account_id = google_service_account.generated_service_account.email
  keepers            = {
    project : var.compute_project_id
    version : var.credential_version
  }
}

module "cromwell" {
  source = "./modules/cromwell"

  credential_version              = var.credential_version
  db_tier                         = var.db_tier
  deployment_project_id           = google_project.project.project_id
  compute_project_id              = var.compute_project_id != null ? var.compute_project_id : var.deployment_project_id
  billing_project_id              = var.billing_project_id != null ? var.billing_project_id : var.deployment_project_id
  region                          = var.region
  zone                            = var.zone
  generated_service_account_email = google_service_account.generated_service_account.email
  allow_deletion                  = var.allow_deletion
  cromwell_version                = var.cromwell_version

  depends_on = [google_project.project]
}

module "cloud_run_ingress" {
  source = "./modules/cloud_run_ingress"

  project_id                      = google_project.project.project_id
  region                          = var.region
  cromwell_ip                     = module.cromwell.network_ip
  cromwell_network_self_link      = module.cromwell.network_self_link
  generated_service_account_email = google_service_account.generated_service_account.email

  depends_on = [google_project.project]
}
