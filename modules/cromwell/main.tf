terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.55.0"
    }
  }
}

resource "google_project_service" "deployment_project_compute" {
  project = var.deployment_project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "compute_project_compute" {
  project = var.compute_project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false

  # This might be the same project, so wait for the first to succeed before enabling this
  depends_on = [google_project_service.deployment_project_compute]
}

resource "google_project_service" "networking" {
  project = var.deployment_project_id
  service = "servicenetworking.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloud_resource_manager" {
  project = var.deployment_project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
}

module "deployment_network" {
  source = "../private_network"

  project_id    = var.deployment_project_id
  region        = var.region
  base_name     = "deployment"
  ip_cidr_range = "10.2.0.0/16"
}

data google_project "compute_project" {
  project_id = var.compute_project_id
}

module "pipeline_network" {
  source = "../private_network"

  project_id    = var.compute_project_id
  region        = var.region
  base_name     = "pipeline-${data.google_project.compute_project.number}"
  ip_cidr_range = "10.0.0.0/8"
}

resource "google_compute_global_address" "cromwell_mysql_ip" {
  project       = var.deployment_project_id
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.deployment_network.network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.deployment_network.network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.cromwell_mysql_ip.name]

  depends_on = [google_project_service.networking]
}

resource "random_password" "root_db_password" {
  keepers = {
    version : var.credential_version
  }

  length = 32
}

resource "google_sql_database_instance" "cromwell_mysql" {
  project          = var.deployment_project_id
  name             = "cromwell-mysql-${random_id.unique_suffix.hex}"
  database_version = "MYSQL_5_7"
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  root_password = random_password.root_db_password.result

  deletion_protection = var.allow_deletion ? false : true

  settings {
    tier = var.db_tier
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = module.deployment_network.network.id
      enable_private_path_for_google_cloud_services = true
    }
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = false
      backup_retention_settings {
        retained_backups = 1
      }
    }
  }
}

resource "random_password" "cromwell_db_password" {
  keepers = {
    version : var.credential_version
  }

  length = 32
}

locals {
  cromwell_db = {
    db_name = "cromwell"
    user    = "cromwell"
    password : random_password.cromwell_db_password.result
  }
  cromwell_bucket_name = "cromwell-output-${random_id.unique_suffix.hex}"
  cromwell_vm          = {
    name           = "cromwell-vm"
    config_path    = "/etc/cromwell/cromwell.conf"
    config_content = templatefile("${path.module}/cromwell.conf", {
      compute_project : var.compute_project_id
      billing_project : var.billing_project_id
      region : var.region
      zone : var.zone
      compute_service_account : google_service_account.pipeline_compute.email
      bucket : local.cromwell_bucket_name
      private_network : module.pipeline_network.network.self_link
      private_subnet : module.pipeline_network.subnet.self_link
      jdbc_url : "jdbc:mysql://${google_sql_database_instance.cromwell_mysql.private_ip_address}:3306/${local.cromwell_db.db_name}?rewriteBatchedStatements=true&useSSL=false"
      db_user : local.cromwell_db.user
      db_password : local.cromwell_db.password
    })
  }
}

resource "google_sql_database" "cromwell" {
  project  = var.deployment_project_id
  instance = google_sql_database_instance.cromwell_mysql.name
  name     = local.cromwell_db.db_name
}

resource "google_sql_user" "cromwell" {
  project  = var.deployment_project_id
  instance = google_sql_database_instance.cromwell_mysql.name
  name     = local.cromwell_db.user
  password = local.cromwell_db.password
}

resource "google_service_account" "cromwell" {
  project      = var.deployment_project_id
  account_id   = "cromwell-sa"
  display_name = "Cromwell Service Account"
}

resource "google_service_account" "pipeline_compute" {
  project      = var.compute_project_id
  account_id   = "pipeline-sa"
  display_name = "Pipeline Compute Service Account"
}

resource "google_storage_bucket" "cromwell_output" {
  project  = var.deployment_project_id
  location = var.region
  name     = local.cromwell_bucket_name

  force_destroy = var.allow_deletion
}

data "google_iam_policy" "cromwell_output" {
  binding {
    role    = "roles/storage.objectAdmin"
    members = [
      "serviceAccount:${google_service_account.cromwell.email}",
      "serviceAccount:${google_service_account.pipeline_compute.email}"
    ]
  }
}

resource "google_storage_bucket_iam_policy" "cromwell_output" {
  bucket      = google_storage_bucket.cromwell_output.name
  policy_data = data.google_iam_policy.cromwell_output.policy_data

  depends_on = [google_project_service.deployment_project_compute]
}

resource "random_id" "unique_suffix" {
  keepers = {
    project = var.deployment_project_id
  }

  byte_length = 8
}

resource "google_project_service" "pipelines" {
  project = var.compute_project_id
  service = "lifesciences.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_iam_member" "deployment_account_deployment_roles" {
  for_each = toset([
    "roles/serviceusage.serviceUsageConsumer",
    "roles/compute.networkUser",
  ])

  project = var.deployment_project_id
  member  = "serviceAccount:${google_service_account.cromwell.email}"
  role    = each.key
}

resource "google_project_iam_member" "deployment_account_compute_roles" {
  for_each = toset([
    "roles/lifesciences.admin",
    "roles/genomics.admin",
  ])

  project = var.compute_project_id
  member  = "serviceAccount:${google_service_account.cromwell.email}"
  role    = each.key
}

resource "google_project_iam_member" "deployment_account_billing_roles" {
  project = var.billing_project_id
  member  = "serviceAccount:${google_service_account.cromwell.email}"
  role    = "roles/serviceusage.serviceUsageConsumer"
}

resource "google_service_account_iam_member" "deployment_account_act_as_compute_account" {
  member             = "serviceAccount:${google_service_account.cromwell.email}"
  role               = "roles/iam.serviceAccountUser"
  service_account_id = "projects/${var.compute_project_id}/serviceAccounts/${google_service_account.pipeline_compute.email}"

  depends_on = [google_project_service.deployment_project_compute]
}

resource "google_project_iam_member" "compute_account_deployment_roles" {
  for_each = toset([
    "roles/compute.networkUser",
  ])

  project = var.deployment_project_id
  member  = "serviceAccount:${google_service_account.pipeline_compute.email}"
  role    = each.key
}

module "cromwell_container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = "broadinstitute/cromwell:85"

    env = [
      {
        name  = "CROMWELL_ARGS"
        value = "server"
      },
      {
        name  = "JAVA_OPTS"
        value = "-XX:+ExitOnOutOfMemoryError -XX:+PrintFlagsFinal -Dconfig.file=/configuration/cromwell.conf"
      }
    ]

    volumeMounts = [
      {
        mountPath = "/configuration/cromwell.conf"
        name      = "config"
        readOnly  = true
      }
    ]
  }

  volumes = [
    {
      name     = "config"
      hostPath = {
        path = local.cromwell_vm.config_path
      }
    }
  ]

  restart_policy = "Always"
}

resource "google_compute_instance" "cromwell_vm" {
  project                   = var.deployment_project_id
  machine_type              = "e2-medium"
  name                      = local.cromwell_vm.name
  allow_stopping_for_update = true
  zone                      = var.zone
  desired_status            = "RUNNING"

  tags = ["cromwell-server"]

  metadata = {
    gce-container-declaration = module.cromwell_container.metadata_value
  }

  labels = {
    container-vm = module.cromwell_container.vm_container_label
  }

  boot_disk {
    initialize_params {
      image = module.cromwell_container.source_image
    }
  }
  network_interface {
    subnetwork = module.deployment_network.subnet.self_link
  }
  service_account {
    email  = google_service_account.cromwell.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = templatefile("${path.module}/startup.sh.tpl", {
    config_path    = local.cromwell_vm.config_path
    config_content = local.cromwell_vm.config_content
  })
}
