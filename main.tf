terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.55.0"
    }
  }
}

provider "google" {
  credentials = file(var.gcp_credential_file)

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

  skip_delete = !var.allow_deletion
}

resource "google_service_account" "generated_service_account" {
  account_id   = "generated-service-account"
  display_name = "Generated Service Account"
  description  = "An generated identity for accessing the Cloud Run service in this project"
  project      = google_project.project.project_id
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