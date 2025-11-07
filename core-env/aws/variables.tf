
variable "common_tags" {
  description = "Tags to be applied to all resources."
  type        = map(string)
  default = {
    "cost_center"         = "sales"
    "owner"               = "eddie.webbinaro@akuity.io"
    "Team"                = "Sales Engineering"
    "iac"                 = "true"
    "critical_until"      = "2035-12-31"
    "data_classification" = "low"
    "purpose"             = "ARAD - Akuity Reference Architecture Demo"
  }
}

variable "email_usernames" {
  description = "Who can act as operator on ARAD resources, by assume operator role."
  default = [
    "eddie.webbinaro",
    "daniel",
    "emily.chen",
  ]

}

variable "sso_iam_role" {
  description = "Name of AWS IAM SSO role to be used for EKS auth by SE team. Assigned by IT"
  default     = "AWSReservedSSO_AdministratorAccess_e2e980dbad09a8b6"
}
output "sso_iam_role" {
  value = var.sso_iam_role
}

variable "limited_assumed_role" {
  default     = "sedemo-iac-operator-role"
  description = "Custom role created by SE team, assumable to anyone in above role, mostly a read-only role."
}

variable "priviledged_assumed_role" {
  default     = "sedemo-iac-pipeline-role"
  description = "Custom role created by SE team, primary used by GHA pipelines, can be used by team if needed."
}