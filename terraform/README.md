# ELSA Quiz Terraform Project

This Terraform project provisions all required GCP infrastructure for the ELSA Quiz real-time vocabulary quiz application.

## Architecture

The infrastructure follows GCP best practices and includes:

- **Cloud Run**: Serverless container platform for the quiz server
- **Cloud SQL (PostgreSQL)**: Managed database for persistent storage
- **Memorystore for Redis**: In-memory cache and session store
- **Cloud Pub/Sub**: Message broker for real-time events
- **VPC Network**: Private network with VPC Access Connector
- **Secret Manager**: Secure secret storage
- **Cloud Monitoring**: Metrics, alerts, and uptime checks
- **Service Accounts**: IAM with least privilege

## Project Structure

```
terraform/
├── backend.tf                    # Terraform state backend configuration
├── environments/
│   ├── dev/                      # Development environment
│   │   ├── main.tf              # Main configuration
│   │   ├── variables.tf         # Variable definitions
│   │   ├── terraform.tfvars     # Variable values (customize this)
│   │   └── outputs.tf           # Output definitions
│   ├── staging/                 # Staging environment (future)
│   └── production/              # Production environment (future)
└── modules/
    ├── vpc/                     # VPC network module
    ├── cloud-sql/               # Cloud SQL module
    ├── memorystore/             # Memorystore for Redis module
    ├── pubsub/                  # Cloud Pub/Sub module
    ├── secrets/                 # Secret Manager module
    ├── service-accounts/        # Service Accounts module
    ├── cloud-run/               # Cloud Run module
    └── monitoring/              # Cloud Monitoring module
```

## Prerequisites

1. **GCP Project**: Create a GCP project
2. **Enable Billing**: Enable billing for the project
3. **Install Tools**:
   ```bash
   # Install Terraform
   brew install terraform

   # Install gcloud CLI
   brew install google-cloud-sdk

   # Authenticate
   gcloud auth login
   gcloud auth application-default login
   ```

4. **Configure Project**:
   ```bash
   export PROJECT_ID="elsa-quiz-dev"
   gcloud config set project $PROJECT_ID
   ```

5. **Create State Bucket**:
   ```bash
   gsutil mb -p $PROJECT_ID -c STANDARD -l us-central1 gs://elsa-quiz-terraform-state
   gsutil versioning set on gs://elsa-quiz-terraform-state
   ```

## Quick Start

### 1. Configure Variables

Edit `environments/dev/terraform.tfvars`:

```hcl
project_id = "your-gcp-project-id"  # Replace with your project ID
region     = "us-central1"
zone       = "us-central1-a"

# Customize as needed
container_image = "gcr.io/cloudrun/hello"  # Placeholder
```

### 2. Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
```

### 3. Plan Infrastructure

```bash
terraform plan
```

Review the plan to ensure it matches expectations.

### 4. Apply Infrastructure

```bash
terraform apply
```

Type `yes` when prompted.

### 5. Get Outputs

```bash
terraform output
```

This will display connection information, URLs, and quick start commands.

## Environment-Specific Configurations

### Development (dev)

- **Cost**: ~$54-69/month
- **Cloud Run**: 0-5 instances, 1 vCPU, 2 GiB RAM
- **Cloud SQL**: db-f1-micro, 10 GB storage, single zone
- **Memorystore**: Basic tier, 1 GB
- **Features**: Auto-shutdown scheduling, relaxed monitoring

### Staging (future)

- **Cost**: ~$400/month
- **Cloud Run**: 1-20 instances, 2 vCPU, 4 GiB RAM
- **Cloud SQL**: db-custom-2-7680, 50 GB, high availability
- **Memorystore**: Standard tier, 5 GB
- **Features**: Production-like, comprehensive monitoring

### Production (future)

- **Cost**: ~$900/month
- **Cloud Run**: 2-100 instances, 2 vCPU, 4 GiB RAM
- **Cloud SQL**: db-custom-4-15360, 150 GB, HA, read replicas
- **Memorystore**: Standard tier, 20 GB
- **Features**: Multi-region, strict security, 24/7 monitoring

## Common Operations

### Deploy a New Cloud Run Revision

```bash
# Build and push container image
docker build -t gcr.io/$PROJECT_ID/quiz-server:latest .
docker push gcr.io/$PROJECT_ID/quiz-server:latest

# Update Cloud Run (or use Cloud Build)
gcloud run deploy quiz-server-dev \
  --image=gcr.io/$PROJECT_ID/quiz-server:latest \
  --region=us-central1 \
  --project=$PROJECT_ID
```

### Connect to Cloud SQL

```bash
# Get connection name
terraform output cloud_sql_connection_name

# Connect via Cloud SQL Proxy
gcloud sql connect quiz-db-dev --user=quiz_app --project=$PROJECT_ID
```

### View Logs

```bash
# Cloud Run logs
gcloud logging read 'resource.type=cloud_run_revision' --limit 50 --project=$PROJECT_ID

# Cloud SQL logs
gcloud logging read 'resource.type=cloudsql_database' --limit 50 --project=$PROJECT_ID
```

### Scale Cloud Run

```bash
# Update min/max instances
gcloud run services update quiz-server-dev \
  --min-instances=1 \
  --max-instances=10 \
  --region=us-central1 \
  --project=$PROJECT_ID
```

### Access Secrets

```bash
# List secrets
gcloud secrets list --project=$PROJECT_ID

# Get secret value
gcloud secrets versions access latest --secret=db-password-dev --project=$PROJECT_ID
```

## Cost Management

### Auto-Shutdown (Development)

The development environment includes Cloud Scheduler jobs that automatically:
- Scale down instances at 6 PM weekdays (PST)
- Scale up instances at 8 AM weekdays (PST)

This reduces costs by ~40% for development environments.

### Budget Alerts

Budget alerts are configured to notify at 50%, 90%, and 100% of monthly budget ($100 for dev).

### Monitor Costs

```bash
# View current month costs
gcloud billing accounts list
gcloud alpha billing projects describe $PROJECT_ID

# Or use the GCP Console: https://console.cloud.google.com/billing
```

## Security

### Service Accounts

Each service has a dedicated service account with minimal required permissions:
- **quiz-server**: Cloud SQL client, Pub/Sub publisher/subscriber, Secret Manager accessor

### Secrets

All sensitive data (passwords, keys) are stored in Secret Manager:
- `db-password-dev`: Cloud SQL database password
- `redis-auth-token-dev`: Redis AUTH token
- `jwt-signing-key-dev`: JWT signing key

### Network Security

- Private IP only for Cloud SQL and Memorystore
- VPC Access Connector for Cloud Run
- Firewall rules: deny all ingress by default
- Cloud Armor DDoS protection (load balancer)

## Troubleshooting

### Terraform State Locked

```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### API Not Enabled

```bash
# Enable required APIs manually
gcloud services enable run.googleapis.com sqladmin.googleapis.com redis.googleapis.com
```

### Cloud SQL Connection Issues

```bash
# Check if Cloud SQL Proxy is needed
gcloud sql instances describe quiz-db-dev --project=$PROJECT_ID

# Verify network connectivity
gcloud compute networks describe quiz-vpc-dev --project=$PROJECT_ID
```

### Cloud Run Deployment Fails

```bash
# Check service logs
gcloud run services logs read quiz-server-dev --region=us-central1 --project=$PROJECT_ID

# Verify service account permissions
gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:serviceAccount:quiz-server-dev@*"
```

## Cleanup

To destroy all resources:

```bash
cd terraform/environments/dev
terraform destroy
```

**Warning**: This will delete all resources including databases. Ensure you have backups if needed.

## CI/CD Integration

The infrastructure supports CI/CD via Cloud Build. See `cloudbuild.yaml` in the application repository for deployment pipeline configuration.

## Support and Documentation

- **Terraform Docs**: https://www.terraform.io/docs
- **GCP Documentation**: https://cloud.google.com/docs
- **Project Design**: See `design.md` for architecture details
- **Requirements**: See `requirements.md` for system requirements

## License

Internal use only - ELSA Corp.

---

**Last Updated**: November 16, 2025
**Terraform Version**: >= 1.5.0
**GCP Provider Version**: ~> 5.0
