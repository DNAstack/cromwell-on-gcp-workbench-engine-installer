variable "gcp_credential_file" {
  type     = string
  nullable = false
  default  = "~/.config/gcloud/application_default_credentials.json"

  description = "The location on the local filesystem of a GCP JSON file key."
}

variable "deployment_project_id" {
  type     = string
  nullable = false

  description = "The ID of a GCP project that will be generated."
}

variable "deployment_project_name" {
  type     = string
  nullable = false

  description = "The name of a GCP project that will be generated."
}

variable "deployment_project_folder_id" {
  type     = string
  nullable = true
  default = null

  description = "The ID of a GCP project folder, in which to create a generated GCP project."
}

variable "deployment_project_billing_account" {
  type     = string
  nullable = false

  description = "The GCP billing account to use for the generated project."
}

variable "compute_project_id" {
  type     = string
  default  = null
  nullable = true

  description = "The ID of the GCP project used for executing pipeline tasks. This project is not generated by this script unless it is set to the deployment_project_id (the default)."
}

variable "billing_project_id" {
  type     = string
  default  = null
  nullable = true

  description = "The ID of the GCP project used for billing. This project is not generated by this script unless it is set to the deployment_project_id (the default)."
}

variable "region" {
  type    = string
  default = "us-central1"

  description = "The GCP region in which to deploy Cromwell and where pipeline jobs are executed."
}

variable "zone" {
  type    = string
  default = "us-central1-c"

  description = "The GCP zone to use for the Cromwell deployment and any associated zonal resources."
}

variable "db_tier" {
  type    = string
  default = "db-f1-micro"

  description = "The tier of database instance to use for Cromwell's MySQL database."
}

variable "credential_version" {
  type    = number
  default = 1

  description = "A variable to force generated database credentials to rotate."
}

variable "allow_deletion" {
  type    = bool
  default = false

  description = "Set this to true in order to allow destroying stateful resources (buckets, DBs, etc.)"
}

variable "cromwell_version" {
  type     = number
  nullable = false
  default = 85

  description = "Set the version of Cromwell to install"
}
