output "service" {
  value = {
    name     = google_cloud_run_service.default.name
    location = google_cloud_run_service.default.location
    urls      = google_cloud_run_service.default.status[*].url
    project  = google_cloud_run_service.default.project
  }
}