variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "tier" {
  description = "Redis tier (BASIC or STANDARD_HA)"
  type        = string
}

variable "memory_size_gb" {
  description = "Redis memory size in GB"
  type        = number
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "REDIS_6_X"
}

variable "vpc_network_id" {
  description = "VPC network ID"
  type        = string
}

variable "reserved_ip_range" {
  description = "Reserved IP range name for Redis"
  type        = string
}
