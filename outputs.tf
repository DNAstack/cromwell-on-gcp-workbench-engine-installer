output "service" {
  value = module.cloud_run_ingress.service
}

output "generated_service_account_email" {
  value = google_service_account.generated_service_account.email
}

output "generated_service_account_private_key" {
  value     = google_service_account_key.generated_service_account_key.private_key
  sensitive = true
}

output "cromwell_output_bucket_name" {
  value = module.cromwell.cromwell_output_bucket_name
}