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
  default = "sedemo-primary"
}

variable "primary_cluser_node_count" {
  default = "2"
}
variable "primary_cluser_node_type" {
  default = "t3.large"
}

variable "ingress_namespace" {
  default = "ingress-nginx"
}

variable "root_domain_name" {
  default     = "akpdemoapps.link"
  description = "This is registered/managed outside Terraform so we can destroy clusters without destroying domain registration."
}