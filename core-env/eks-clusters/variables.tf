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

variable "twingate_secret_arn" {
  default     = "arn:aws:secretsmanager:us-west-2:218691292270:secret:sedemo/twingate-VTxfq2"
  description = "The ARN of the Twingate acess-token and refresh-token in AWS Secrets Manager."
  sensitive   = true
}

variable "twingate_network" {
  default     = "akuity"
  type        = string
  description = "The Twingate network slug (the subdomain only, e.g. 'akuity' for akuity.twingate.com). The chart appends '.twingate.com'."
}

variable "twingate_api_token_secret_id" {
  default     = "sedemo/twingate-api-token"
  type        = string
  description = "Secrets Manager secret holding the Twingate API token (plain string) used to manage the EKS API Resource."
}

variable "twingate_remote_network_name" {
  default     = "TODO-remote-network"
  type        = string
  description = "Twingate Remote Network the connector belongs to. The EKS API Resource is created in it."
}

variable "twingate_gha_service_account_name" {
  default     = "TODO-gha-service-account"
  type        = string
  description = "Twingate Service Account used by GitHub Actions runners (key in sedemo/twingate-gha-service-key)."
}

variable "twingate_eks_api_groups" {
  default     = []
  type        = list(string)
  description = "Twingate Group names whose members may reach the EKS API (kubectl) through Twingate."
}

variable "twingate_log_level" {
  # Set to debug for the initial deployment to diagnose connector issues; lower to error once stable.
  default     = "debug"
  type        = string
  description = "The log level for Twingate. Values are [error, warn, info, debug].  Default is error."
}

variable "twingate_log_analytics" {
  # Enabled for the initial deployment; set to null to disable once stable.
  default     = "v2"
  type        = string
  description = "Whether to enable real-time connection logs for Twingate.  Values are [null, v1, v2].  v1 is the legacy log format, v2 is the new log format.  If null, logging is disabled.  Default is null."
}
