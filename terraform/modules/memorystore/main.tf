# Memorystore for Redis Module

locals {
  instance_name = "quiz-redis-${var.env}"
}

resource "google_redis_instance" "instance" {
  name               = local.instance_name
  project            = var.project_id
  region             = var.region
  tier               = var.tier
  memory_size_gb     = var.memory_size_gb
  redis_version      = var.redis_version
  display_name       = "Quiz Redis Instance (${var.env})"
  reserved_ip_range  = var.reserved_ip_range
  
  authorized_network = var.vpc_network_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  
  auth_enabled       = var.env != "dev" # Enable AUTH in staging/prod
  transit_encryption_mode = var.env == "prod" ? "SERVER_AUTHENTICATION" : "DISABLED"

  labels = var.labels

  redis_configs = {
    maxmemory-policy = "allkeys-lru"
    timeout          = "300"
  }

  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 3
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}
