variable "project_id" {
  description = "GCP Project ID"
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

variable "topics" {
  description = "List of topic names to create"
  type        = list(string)
}

variable "subscriptions" {
  description = "Map of subscriptions to create"
  type = map(object({
    topic                      = string
    ack_deadline_seconds       = number
    message_retention_duration = string
    retain_acked_messages      = bool
    enable_message_ordering    = bool
    dead_letter_topic          = optional(string)
    max_delivery_attempts      = optional(number, 5)
  }))
}
