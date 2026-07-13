variable "project_id" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
}

variable "base_name" {
  type     = string
  nullable = false
}

variable "ip_cidr_range" {
  type     = string
  nullable = false
}

variable "tcp_time_wait_timeout_sec" {
  description = "TCP TIME_WAIT timeout in seconds for Cloud NAT. Set to 120 to preserve previous default (Google changing new gateways to 30s)."
  type        = number
  default     = 120
}
