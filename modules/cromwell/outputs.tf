output "network_ip" {
  value = google_compute_instance.cromwell_vm.network_interface[0].network_ip
}

output "network_self_link" {
  value = module.deployment_network.network.self_link
}

output "deployment_network_name" {
  value = module.deployment_network.network.name
}

output "cromwell_output_bucket_name" {
  value = google_storage_bucket.cromwell_output.name
}

output "pipeline_sa_email" {
  value = google_service_account.pipeline_compute.email
}