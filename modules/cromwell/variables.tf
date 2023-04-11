variable "deployment_project_id" {
  type     = string
  nullable = false
}

variable "compute_project_id" {
  type     = string
  nullable = false
}

variable "billing_project_id" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
}

variable "zone" {
  type     = string
  nullable = false
}

variable "credential_version" {
  type     = number
  nullable = false
}

variable "db_tier" {
  type     = string
  nullable = false
}

variable "allow_deletion" {
  type    = bool
  default = false
}

variable "generated_service_account_email" {
  type     = string
  nullable = false
}

variable "cromwell_version" {
  type     = string
  nullable = false
}
