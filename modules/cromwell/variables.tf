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

variable "sql_maintenance_window_day" {
  description = "The day of week (1-7), starting on Monday for the maintenance window"
  type        = number
  default     = 1
}

variable "sql_maintenance_window_hour" {
  description = "The hour of day (0-23), ignored if day not set for the maintenance window (UTC)"
  type        = number
}

variable "sql_profile" {
  description = "Database profile to use for the Cromwell SQL database"
  type        = string
  default     = "slick.jdbc.MySQLProfile$"
}

variable "sql_driver" {
  description = "Database driver to use for the Cromwell SQL database"
  type        = string
  default     = "com.mysql.cj.jdbc.Driver"
}

variable "sql_database_version" {
  description = "Database version to use for the Cromwell SQL database"
  type     = string
}

variable "file_suffixes_to_delete" {
  description = "List of file suffixes used in the deletion lifecycle policy"
  type        = list(string)
  default     = [".gz", ".bam", ".bed", ".bw", ".out", ".tsv", ".bai", ".log"]
}

variable "file_age_days" {
  description = "Number of days after which files with the specified suffixes will be deleted"
  type        = number
  default     = 14
}
