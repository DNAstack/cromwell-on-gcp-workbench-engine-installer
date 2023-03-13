output "network_ip" {
  value = google_compute_instance.cromwell_vm.network_interface[0].network_ip
}

output "network_self_link" {
  value = module.deployment_network.network.self_link
}