output "service" {
  value = module.cloud_run_ingress.service
}

output "generated_service_account_email" {
  value = module.cloud_run_ingress.generated_service_account_email
}
