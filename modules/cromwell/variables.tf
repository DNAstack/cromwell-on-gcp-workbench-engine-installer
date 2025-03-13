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

variable "additional_buckets" {
  description = "Additional buckets to add to the policy"
  type = list(object({
    name    = string
    project = string
  }))
  default = []
}

variable "google_organization" {
  description = "The name of the organization in the resource hierarchy that the project belongs to"
  type        = string
  default     = "dnastack.com"
}

variable "bucket_lister_role_name" {
  description = "The name of the custom role that contains the storage.buckets.get permission"
  type        = string
  default     = "BucketLister"
}

variable "cos_image_name" {
  description = "Name of a specific COS image to use instead of the latest cos family image"
  type        = string
  default     = "cos-stable-117-18613-164-68"
}

variable "cos_image_family" {
    description = "The COS image family to use (eg: stable, beta, or dev)"
    type        = string
    default     = "cos-stable"
}
