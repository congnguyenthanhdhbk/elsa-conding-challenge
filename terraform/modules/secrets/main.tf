# Secret Manager Module

resource "google_secret_manager_secret" "secrets" {
  for_each = nonsensitive(var.secrets)

  secret_id = "${each.key}-${var.env}"
  project   = var.project_id
  labels    = var.labels

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = false # Set to true for production
  }
}

resource "google_secret_manager_secret_version" "secret_versions" {
  for_each = nonsensitive(var.secrets)

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value.secret_data
}
