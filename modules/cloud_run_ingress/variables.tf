variable "project_id" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
}

variable "cromwell_ip" {
  type     = string
  nullable = false
}

variable "cromwell_network_self_link" {
  type     = string
  nullable = false
}

variable "generated_service_account_email" {
  type     = string
  nullable = false
}