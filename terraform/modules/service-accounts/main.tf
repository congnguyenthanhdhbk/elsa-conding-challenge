# Service Accounts Module

resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts

  account_id   = "${each.key}-${var.env}"
  project      = var.project_id
  display_name = each.value.display_name
  description  = each.value.description
}

resource "google_project_iam_member" "service_account_roles" {
  for_each = merge([
    for sa_key, sa_value in var.service_accounts : {
      for role in sa_value.roles :
      "${sa_key}-${role}" => {
        service_account = google_service_account.service_accounts[sa_key].email
        role            = role
      }
    }
  ]...)

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${each.value.service_account}"
}
