# Google Cloud Platform Architecture Instructions

## Overview
This document provides guidelines for designing and implementing GCP-based solutions in this project.

## GCP Service Selection

### Compute Services
- **Cloud Run** - Preferred for containerized stateless applications
  - Auto-scaling, pay-per-use
  - Use for API services, web applications, background workers
- **Cloud Functions** - For event-driven, single-purpose functions
  - Use for lightweight event handlers, webhooks
  - Keep functions small and focused
- **GKE (Google Kubernetes Engine)** - For complex microservices requiring orchestration
  - Only when Cloud Run limitations are reached

### Data Storage
- **Cloud SQL** - For relational data requiring ACID compliance
  - PostgreSQL preferred for advanced features
  - Use connection pooling (Cloud SQL Proxy or private IP)
- **Cloud Firestore** - For document-based, real-time data
  - Design collections for query patterns
  - Use subcollections sparingly
- **Cloud Storage** - For object/blob storage
  - Organize with clear bucket naming: `{project}-{environment}-{purpose}`
  - Use lifecycle policies for cost optimization

### Messaging & Events
- **Pub/Sub** - For asynchronous messaging and event distribution
  - Design idempotent message handlers
  - Use dead-letter topics for failed messages
  - Set appropriate acknowledgment deadlines
- **Cloud Tasks** - For scheduled and deferred work
  - Use for reliable task execution with retries

### Monitoring & Observability
- **Cloud Logging** - Centralized logging
  - Use structured logging (JSON format)
  - Add trace context for request correlation
- **Cloud Monitoring** - Metrics and alerting
  - Create dashboards for key business metrics
  - Set up alerts for error rates, latency, resource usage
- **Cloud Trace** - Distributed tracing
  - Enable for all HTTP requests
  - Trace cross-service calls

## Architecture Patterns

### Microservices Communication
- Use **Cloud Run** with **Cloud Load Balancing** for public APIs
- Use **Pub/Sub** for async communication between services
- Implement **Circuit Breaker** pattern for external dependencies
- Use **Service Mesh** (like Istio) only when needed for complex routing

### Security Best Practices
- **IAM & Service Accounts**
  - Use separate service accounts per service
  - Follow principle of least privilege
  - Never commit service account keys - use Workload Identity
- **Secrets Management**
  - Store secrets in **Secret Manager**
  - Rotate secrets regularly
  - Access secrets at runtime, not build time
- **VPC & Networking**
  - Use VPC Service Controls for data perimeter
  - Enable Private Google Access
  - Use Cloud Armor for DDoS protection

### CI/CD Integration
- Use **Cloud Build** for building and deploying
  - Define build steps in `cloudbuild.yaml`
  - Use substitution variables for environment-specific configs
- Use **Artifact Registry** for container images
  - Tag images with git commit SHA
  - Scan images for vulnerabilities

### Cost Optimization
- Set **budgets and alerts** in Cloud Billing
- Use **committed use discounts** for predictable workloads
- Implement **auto-scaling policies** based on actual load
- Use **preemptible VMs** for batch processing
- Enable **Cloud CDN** for static content

### Disaster Recovery
- Define **RPO (Recovery Point Objective)** and **RTO (Recovery Time Objective)**
- Enable **point-in-time recovery** for databases
- Use **multi-region deployment** for critical services
- Regularly test backup restoration procedures
- Document runbooks for common failure scenarios

## Resource Naming Conventions
```
Projects:     {org}-{project}-{env}
Services:     {service-name}-{env}
Buckets:      {project}-{env}-{purpose}
Topics:       {event-name}-topic
Subscriptions: {service-name}-{topic-name}-sub
```

## Environment Strategy
- **Development** - Single region, minimal redundancy, auto-shutdown policies
- **Staging** - Production-like, smaller scale, used for integration testing
- **Production** - Multi-region (if required), high availability, comprehensive monitoring

## Infrastructure as Code
- Use **Terraform** for infrastructure provisioning
  - Organize by environment and service
  - Use remote state in Cloud Storage
  - Enable state locking
- Store Terraform state in GCS with versioning enabled
- Use modules for reusable components

## Compliance & Data Governance
- Enable **audit logging** for all services
- Use **Data Loss Prevention (DLP) API** for sensitive data
- Implement **VPC Service Controls** for data exfiltration prevention
- Tag resources appropriately for cost allocation and governance

---
*Refer to GCP best practices documentation for detailed implementation guidance*
