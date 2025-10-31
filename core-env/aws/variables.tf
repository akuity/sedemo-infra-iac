
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


variable "demo_domain" {
  description = "Domain apps will be exposed via ingress"
  type = string
  default = "demoapps.akuity.io"
}

variable "email_usernames" {
  description = "Who can act as operator on ARAD resources, by assume operator role."
}

variable "sso_iam_role" {
  description = "Name of AWS IAM SSO role to be used for EKS auth by SE team. Assigned by IT"
  default = "AWSReservedSSO_AdministratorAccess_e2e980dbad09a8b6" 
}

variable "iac_assumed_role" {
    default = "iac-pipeline-role"
    description = "Custom role created by SE team, assumable to anyone in above role."
}