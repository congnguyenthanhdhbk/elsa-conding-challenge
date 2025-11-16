variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "notification_channels" {
  description = "Notification channels for alerts"
  type = list(object({
    display_name = string
    type         = string
    labels       = map(string)
  }))
  default = []
}

variable "alert_policies" {
  description = "Alert policies to create"
  type = map(object({
    display_name = string
    filter       = optional(string, "")
    enabled      = bool
    conditions = object({
      threshold_value     = number
      duration           = string
      comparison         = string
      aggregation_period = string
    })
    documentation = optional(string, "")
  }))
  default = {}
}

variable "uptime_checks" {
  description = "Uptime checks to create"
  type = map(object({
    display_name = string
    timeout      = string
    period       = string
    http_check = object({
      path         = string
      port         = number
      use_ssl      = bool
      validate_ssl = bool
    })
    monitored_resource = object({
      type   = string
      labels = map(string)
    })
  }))
  default = {}
}
