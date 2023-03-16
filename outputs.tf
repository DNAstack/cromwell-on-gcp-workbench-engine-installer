output "service" {
  value = module.cloud_run_ingress.service
}

output "generated_service_account_email" {
  value = google_service_account.generated_service_account.email
}
