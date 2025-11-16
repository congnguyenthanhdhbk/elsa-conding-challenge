# Development Environment Outputs

output "project_id" {
  description = "GCP Project ID"
  value       = local.project_id
}

output "region" {
  description = "GCP Region"
  value       = local.region
}

output "environment" {
  description = "Environment name"
  value       = local.env
}

# Network Outputs
output "vpc_network_id" {
  description = "VPC Network ID"
  value       = module.vpc.network_id
}

output "vpc_network_name" {
  description = "VPC Network Name"
  value       = module.vpc.network_name
}

output "vpc_connector_id" {
  description = "VPC Access Connector ID"
  value       = module.vpc.vpc_connector_id
}

# Cloud SQL Outputs
output "cloud_sql_instance_name" {
  description = "Cloud SQL instance name"
  value       = module.cloud_sql.instance_name
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL connection name"
  value       = module.cloud_sql.connection_name
}

output "cloud_sql_private_ip" {
  description = "Cloud SQL private IP address"
  value       = module.cloud_sql.private_ip
  sensitive   = true
}

output "cloud_sql_database_name" {
  description = "Cloud SQL database name"
  value       = module.cloud_sql.database_name
}

output "cloud_sql_user" {
  description = "Cloud SQL user"
  value       = module.cloud_sql.user
}

# Memorystore Outputs
output "redis_instance_id" {
  description = "Redis instance ID"
  value       = module.memorystore.instance_id
}

output "redis_host" {
  description = "Redis host address"
  value       = module.memorystore.host
  sensitive   = true
}

output "redis_port" {
  description = "Redis port"
  value       = module.memorystore.port
}

output "redis_memory_size_gb" {
  description = "Redis memory size in GB"
  value       = module.memorystore.memory_size_gb
}

# Pub/Sub Outputs
output "pubsub_topics" {
  description = "Created Pub/Sub topics"
  value       = module.pubsub.topic_names
}

output "pubsub_subscriptions" {
  description = "Created Pub/Sub subscriptions"
  value       = module.pubsub.subscription_names
}

# Cloud Run Outputs
output "cloud_run_service_url" {
  description = "Cloud Run service URL"
  value       = module.cloud_run.service_url
}

output "cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = module.cloud_run.service_name
}

output "cloud_run_service_account_email" {
  description = "Cloud Run service account email"
  value       = module.service_accounts.service_account_emails["quiz-server"]
}

# Secret Manager Outputs
output "secret_names" {
  description = "Created secret names"
  value       = module.secrets.secret_names
}

# Connection Information
output "connection_info" {
  description = "Connection information for services"
  sensitive   = true
  value = {
    cloud_run_url         = module.cloud_run.service_url
    websocket_endpoint    = "${module.cloud_run.service_url}/ws"
    health_check_endpoint = "${module.cloud_run.service_url}/health/ready"
    cloud_sql_connection  = module.cloud_sql.connection_name
    redis_endpoint        = "${module.memorystore.host}:${module.memorystore.port}"
  }
}

# Cost Estimate
output "estimated_monthly_cost" {
  description = "Estimated monthly cost in USD (approximate)"
  value = {
    cloud_run      = "~$5-20 (pay-per-use, depends on traffic)"
    cloud_sql      = "~$7 (db-f1-micro)"
    memorystore    = "~$35 (1 GB Basic tier)"
    networking     = "~$5"
    pubsub         = "~$2"
    total_estimate = "~$54-69/month"
    note           = "Actual costs depend on usage patterns. Auto-shutdown reduces costs by ~40%"
  }
}

# Quick Start Commands
output "quick_start_commands" {
  description = "Quick start commands for common operations"
  value = {
    deploy_cloud_run = "gcloud run deploy ${local.service_name} --image=${var.container_image} --region=${local.region} --project=${local.project_id}"
    connect_to_sql   = "gcloud sql connect ${module.cloud_sql.instance_name} --user=${module.cloud_sql.user} --project=${local.project_id}"
    view_logs        = "gcloud logging read 'resource.type=cloud_run_revision AND resource.labels.service_name=${local.service_name}' --limit 50 --project=${local.project_id}"
    get_service_url  = "gcloud run services describe ${local.service_name} --region=${local.region} --project=${local.project_id} --format='value(status.url)'"
  }
}
