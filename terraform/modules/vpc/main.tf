# VPC Network Module - Main Configuration

locals {
  network_name = "quiz-vpc-${var.env}"
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = local.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC network for quiz application (${var.env})"
}

# Subnet for Cloud Run VPC Connector
resource "google_compute_subnetwork" "subnet" {
  name          = "${local.network_name}-subnet"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr
  
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# VPC Access Connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  name          = "quiz-vpc-connector-${var.env}"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.connector_cidr
  
  min_instances = 2
  max_instances = var.env == "dev" ? 3 : 10
  
  machine_type = var.env == "dev" ? "e2-micro" : "e2-standard-4"
}

# Reserved IP range for Memorystore Redis
resource "google_compute_global_address" "redis_ip_range" {
  name          = "redis-ip-range-${var.env}"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 29
  network       = google_compute_network.vpc.id
}

# Private VPC Connection for Cloud SQL and Memorystore
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.redis_ip_range.name]
}

# Firewall rule: Allow internal traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "${local.network_name}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]
  priority      = 1000
}

# Firewall rule: Allow health checks from Google
resource "google_compute_firewall" "allow_health_check" {
  name    = "${local.network_name}-allow-health-check"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [
    "35.191.0.0/16",  # Google Cloud health check ranges
    "130.211.0.0/22"
  ]
  
  target_tags = ["cloud-run"]
  priority    = 1000
}

# Firewall rule: Deny all ingress by default (explicit)
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${local.network_name}-deny-all-ingress"
  project = var.project_id
  network = google_compute_network.vpc.name

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65534 # Lowest priority
}

# Cloud Router for NAT (if needed for egress)
resource "google_compute_router" "router" {
  name    = "${local.network_name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT for outbound internet access
resource "google_compute_router_nat" "nat" {
  name    = "${local.network_name}-nat"
  project = var.project_id
  router  = google_compute_router.router.name
  region  = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
