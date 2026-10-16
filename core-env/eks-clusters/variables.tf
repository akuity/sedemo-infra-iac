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

variable "eks_endpoint_public_access" {
  # TEMPORARY true only while bootstrapping a fresh cluster: akuity-bootstrap
  # installs the Argo CD agent through the API, and the Twingate connector only
  # exists once Argo CD has synced it. Set back to false once the connector is
  # online and the Twingate Resource points at the new endpoint. See README.
  description = "Expose the EKS API endpoint publicly. Keep false outside of bootstrap; access is via Twingate."
  type        = bool
  default     = false
}

variable "root_domain_name" {
  default     = "akpdemoapps.link"
  description = "This is registered/managed outside Terraform so we can destroy clusters without destroying domain registration."
}

