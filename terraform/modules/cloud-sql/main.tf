# Cloud SQL Module - PostgreSQL Instance

locals {
  instance_name = "quiz-db-${var.env}"
}

# Random password for database user
resource "random_password" "db_password" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Cloud SQL Instance
resource "google_sql_database_instance" "instance" {
  name             = local.instance_name
  project          = var.project_id
  region           = var.region
  database_version = var.database_version

  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    disk_autoresize   = true
    disk_autoresize_limit = var.disk_size * 5 # Auto-expand up to 5x initial size

    user_labels = var.labels

    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = "03:00"
      point_in_time_recovery_enabled = var.env == "prod"
      transaction_log_retention_days = var.backup_retention
      backup_retention_settings {
        retained_backups = var.backup_retention
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled    = false # No public IP
      private_network = var.vpc_network_id
      require_ssl     = true

      # Allow connections only from private network
      authorized_networks {
        name  = "internal"
        value = "10.0.0.0/8"
      }
    }

    database_flags {
      name  = "max_connections"
      value = var.env == "dev" ? "100" : "500"
    }

    database_flags {
      name  = "shared_buffers"
      value = var.env == "dev" ? "128MB" : "256MB"
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "1000" # Log queries slower than 1s
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    maintenance_window {
      day          = 7 # Sunday
      hour         = 3 # 3 AM
      update_track = "stable"
    }
  }

  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}

# Database
resource "google_sql_database" "database" {
  name     = var.database_name
  project  = var.project_id
  instance = google_sql_database_instance.instance.name
  charset  = "UTF8"
  collation = "en_US.UTF8"
}

# Database User
resource "google_sql_user" "user" {
  name     = var.database_user
  project  = var.project_id
  instance = google_sql_database_instance.instance.name
  password = random_password.db_password.result
}

# SSL Certificate for secure connections
resource "google_sql_ssl_cert" "client_cert" {
  common_name = "${var.env}-client-cert"
  instance    = google_sql_database_instance.instance.name
  project     = var.project_id
}
