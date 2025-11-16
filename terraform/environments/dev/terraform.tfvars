# Development Environment Configuration
# Copy this file to terraform.tfvars and update with your values

project_id = "quantum-petal-401209" # Replace with your actual GCP project ID
region     = "us-central1"
zone       = "us-central1-a"

# Cloud SQL
cloud_sql_tier      = "db-f1-micro"
cloud_sql_disk_size = 10

# Memorystore
redis_memory_size_gb = 1

# Cloud Run
container_image        = "gcr.io/elsa-quiz-dev/quiz-server:latest"
cloud_run_max_instances = 5

# Monitoring
notification_channels = [] # Add your notification channel IDs

# Budget
monthly_budget_amount    = 100
budget_alert_thresholds  = [0.5, 0.9, 1.0]
