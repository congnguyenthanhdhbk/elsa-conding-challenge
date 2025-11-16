# Development Environment - ELSA Quiz Application
# This configuration provisions all required GCP resources for the dev environment

locals {
  project_id = var.project_id
  region     = var.region
  zone       = var.zone
  env        = "dev"
  
  # Service naming convention: {service-name}-{env}
  service_name = "quiz-server-${local.env}"
  
  # Labels for resource management
  common_labels = {
    environment = local.env
    project     = "elsa-quiz"
    managed_by  = "terraform"
    team        = "engineering"
  }
}

# Enable required GCP APIs
module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.0"

  project_id = local.project_id

  activate_apis = [
    "compute.googleapis.com",           # Compute Engine API
    "run.googleapis.com",               # Cloud Run API
    "vpcaccess.googleapis.com",         # VPC Access API
    "sqladmin.googleapis.com",          # Cloud SQL Admin API
    "redis.googleapis.com",             # Memorystore for Redis API
    "pubsub.googleapis.com",            # Cloud Pub/Sub API
    "secretmanager.googleapis.com",     # Secret Manager API
    "logging.googleapis.com",           # Cloud Logging API
    "monitoring.googleapis.com",        # Cloud Monitoring API
    "cloudtrace.googleapis.com",        # Cloud Trace API
    "cloudbuild.googleapis.com",        # Cloud Build API
    "artifactregistry.googleapis.com",  # Artifact Registry API
    "servicenetworking.googleapis.com", # Service Networking API
    "cloudscheduler.googleapis.com",    # Cloud Scheduler API
  ]

  disable_services_on_destroy = false
}

# VPC Network
module "vpc" {
  source = "../../modules/vpc"

  project_id = local.project_id
  region     = local.region
  env        = local.env
  labels     = local.common_labels

  depends_on = [module.project_services]
}

# Cloud SQL (PostgreSQL)
module "cloud_sql" {
  source = "../../modules/cloud-sql"

  project_id = local.project_id
  region     = local.region
  env        = local.env
  labels     = local.common_labels

  # Development configuration (minimal resources)
  tier                = var.cloud_sql_tier
  disk_size           = var.cloud_sql_disk_size
  disk_type           = "PD_SSD"
  availability_type   = "ZONAL" # Single zone for dev
  backup_enabled      = true
  backup_retention    = 3 # 3 days for dev
  deletion_protection = false # Allow deletion in dev

  # Network
  vpc_network_id = module.vpc.network_id
  private_ip_enabled = true

  # Database configuration
  database_name = "quiz_db"
  database_user = "quiz_app"

  depends_on = [module.vpc]
}

# Memorystore for Redis
module "memorystore" {
  source = "../../modules/memorystore"

  project_id = local.project_id
  region     = local.region
  env        = local.env
  labels     = local.common_labels

  # Development configuration (basic tier)
  tier            = "BASIC" # No replica for dev
  memory_size_gb  = var.redis_memory_size_gb
  redis_version   = "REDIS_6_X"
  
  # Network
  vpc_network_id = module.vpc.network_id
  reserved_ip_range = module.vpc.redis_reserved_ip_range

  depends_on = [module.vpc]
}

# Cloud Pub/Sub Topics and Subscriptions
module "pubsub" {
  source = "../../modules/pubsub"

  project_id = local.project_id
  env        = local.env
  labels     = local.common_labels

  # Topics for different event types
  topics = [
    "quiz-events-topic",
    "session-events-topic",
    "score-updates-topic",
    "leaderboard-updates-topic"
  ]

  # Subscriptions with appropriate configurations
  subscriptions = {
    "quiz-server-sub" = {
      topic                      = "quiz-events-topic"
      ack_deadline_seconds       = 60
      message_retention_duration = "86400s" # 24 hours
      retain_acked_messages      = false
      enable_message_ordering    = false
      dead_letter_topic          = "quiz-events-dead-letter"
      max_delivery_attempts      = 5
    }
    "session-events-sub" = {
      topic                      = "session-events-topic"
      ack_deadline_seconds       = 60
      message_retention_duration = "86400s"
      retain_acked_messages      = false
      enable_message_ordering    = true # Ordered session events
      dead_letter_topic          = "session-events-dead-letter"
      max_delivery_attempts      = 5
    }
    "score-updates-sub" = {
      topic                      = "score-updates-topic"
      ack_deadline_seconds       = 30
      message_retention_duration = "3600s" # 1 hour (ephemeral)
      retain_acked_messages      = false
      enable_message_ordering    = false
      dead_letter_topic          = "score-updates-dead-letter"
      max_delivery_attempts      = 3
    }
  }

  depends_on = [module.project_services]
}

# Secret Manager secrets
module "secrets" {
  source = "../../modules/secrets"

  project_id = local.project_id
  env        = local.env
  labels     = local.common_labels

  secrets = {
    "db-password" = {
      secret_data = module.cloud_sql.db_password
    }
    "redis-auth-token" = {
      secret_data = random_password.redis_auth.result
    }
    "jwt-signing-key" = {
      secret_data = random_password.jwt_key.result
    }
  }

  depends_on = [module.project_services]
}

# Random passwords for secrets
resource "random_password" "redis_auth" {
  length  = 32
  special = true
}

resource "random_password" "jwt_key" {
  length  = 64
  special = false
}

# Service Account for Cloud Run
module "service_accounts" {
  source = "../../modules/service-accounts"

  project_id = local.project_id
  env        = local.env

  service_accounts = {
    quiz-server = {
      display_name = "Quiz Server Service Account (${local.env})"
      description  = "Service account for Cloud Run quiz server in ${local.env}"
      roles = [
        "roles/cloudsql.client",
        "roles/pubsub.publisher",
        "roles/pubsub.subscriber",
        "roles/secretmanager.secretAccessor",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter",
        "roles/cloudtrace.agent"
      ]
    }
  }

  depends_on = [module.project_services]
}

# Cloud Run Service
module "cloud_run" {
  source = "../../modules/cloud-run"

  project_id = local.project_id
  region     = local.region
  env        = local.env
  labels     = local.common_labels

  service_name         = local.service_name
  container_image      = var.container_image
  service_account_email = module.service_accounts.service_account_emails["quiz-server"]

  # Development configuration (minimal resources)
  cpu_limit              = "1000m" # 1 vCPU
  memory_limit           = "2Gi"
  max_instances          = var.cloud_run_max_instances
  min_instances          = 0 # Allow cold starts in dev
  container_concurrency  = 80
  timeout_seconds        = 300

  # VPC configuration
  vpc_connector_id = module.vpc.vpc_connector_id

  # Environment variables
  env_vars = {
    ENV                   = local.env
    PROJECT_ID            = local.project_id
    REGION                = local.region
    CLOUD_SQL_CONNECTION  = module.cloud_sql.connection_name
    REDIS_HOST            = module.memorystore.host
    REDIS_PORT            = tostring(module.memorystore.port)
    LOG_LEVEL             = "debug" # Verbose logging in dev
    ENABLE_ANALYTICS      = "false"
    MAX_CONNECTIONS_PER_INSTANCE = "1000"
  }

  # Secret environment variables
  secret_env_vars = {
    DB_PASSWORD = {
      secret_name = "db-password"
      version     = "latest"
    }
    REDIS_AUTH_TOKEN = {
      secret_name = "redis-auth-token"
      version     = "latest"
    }
    JWT_SIGNING_KEY = {
      secret_name = "jwt-signing-key"
      version     = "latest"
    }
  }

  # Allow unauthenticated access for dev testing
  allow_unauthenticated = true

  depends_on = [
    module.vpc,
    module.cloud_sql,
    module.memorystore,
    module.secrets,
    module.service_accounts
  ]
}

# Cloud Monitoring
module "monitoring" {
  source = "../../modules/monitoring"

  project_id = local.project_id
  env        = local.env

  # Notification channels
  notification_channels = var.notification_channels

  # Alert policies (relaxed for dev)
  alert_policies = {
    high_error_rate = {
      display_name = "[${upper(local.env)}] High Error Rate"
      conditions = {
        threshold_value     = 0.05 # 5% error rate
        duration           = "300s" # 5 minutes
        comparison         = "COMPARISON_GT"
        aggregation_period = "60s"
      }
      enabled = true
    }
    high_latency = {
      display_name = "[${upper(local.env)}] High Latency (P99)"
      conditions = {
        threshold_value     = 1000 # 1 second
        duration           = "300s"
        comparison         = "COMPARISON_GT"
        aggregation_period = "60s"
      }
      enabled = true
    }
  }

  # Uptime checks
  uptime_checks = {
    cloud_run_health = {
      display_name = "Quiz Server Health Check (${local.env})"
      timeout      = "10s"
      period       = "60s"
      http_check = {
        path         = "/health/live"
        port         = 443
        use_ssl      = true
        validate_ssl = true
      }
      monitored_resource = {
        type = "cloud_run_revision"
        labels = {
          project_id   = local.project_id
          service_name = local.service_name
          location     = local.region
        }
      }
    }
  }

  depends_on = [module.cloud_run]
}

# Cloud Scheduler (auto-shutdown for cost savings)
resource "google_cloud_scheduler_job" "scale_down_evening" {
  name             = "quiz-server-scale-down-${local.env}"
  description      = "Scale down Cloud Run instances in the evening to save costs"
  schedule         = "0 18 * * 1-5" # 6 PM weekdays (PST)
  time_zone        = "America/Los_Angeles"
  attempt_deadline = "320s"
  region           = local.region
  project          = local.project_id

  http_target {
    http_method = "PATCH"
    uri         = "https://run.googleapis.com/v2/projects/${local.project_id}/locations/${local.region}/services/${local.service_name}"
    
    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode(jsonencode({
      apiVersion = "serving.knative.dev/v1"
      kind       = "Service"
      metadata = {
        annotations = {
          "autoscaling.knative.dev/minScale" = "0"
          "autoscaling.knative.dev/maxScale" = "2"
        }
      }
    }))

    oauth_token {
      service_account_email = module.service_accounts.service_account_emails["quiz-server"]
    }
  }

  depends_on = [module.cloud_run, module.project_services]
}

resource "google_cloud_scheduler_job" "scale_up_morning" {
  name             = "quiz-server-scale-up-${local.env}"
  description      = "Scale up Cloud Run instances in the morning"
  schedule         = "0 8 * * 1-5" # 8 AM weekdays (PST)
  time_zone        = "America/Los_Angeles"
  attempt_deadline = "320s"
  region           = local.region
  project          = local.project_id

  http_target {
    http_method = "PATCH"
    uri         = "https://run.googleapis.com/v2/projects/${local.project_id}/locations/${local.region}/services/${local.service_name}"
    
    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode(jsonencode({
      apiVersion = "serving.knative.dev/v1"
      kind       = "Service"
      metadata = {
        annotations = {
          "autoscaling.knative.dev/minScale" = "0"
          "autoscaling.knative.dev/maxScale" = "5"
        }
      }
    }))

    oauth_token {
      service_account_email = module.service_accounts.service_account_emails["quiz-server"]
    }
  }

  depends_on = [module.cloud_run, module.project_services]
}
