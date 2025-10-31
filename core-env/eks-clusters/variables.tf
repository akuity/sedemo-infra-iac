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

variable "primary_cluster_name" {
  default = "sedemo-primary-vpc"
}

variable "primary_cluser_node_count" {
  default = "2"
}
variable "primary_cluser_node_type" {
  default = "t4g.large" #ARM Graviton processors (T4) offer burstable price effective performance.
}