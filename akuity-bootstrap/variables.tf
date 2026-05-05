#
# This file declares the variables used in the akuity-boot module.
# Actual values may be provided via a terraform.tfvars file or at runtime in the CLI.
#

variable "org_name" {
  description = "The name of the Akuity organization."
  type        = string
  default     = "demo"
}

variable "akp_instance_name" {
  description = "The name of the AKP instance to create or update."
  type        = string
  default     = "se-demo-iac"
}

variable "akp_instance_version" {
  description = "The version of the AKP instance to create or update."
  type        = string
  default     = "v3.3.9-ak.87"
}

variable "kargo_instance_name" {
  description = "The name of the Kargo instance to create or update."
  type        = string
  default     = "se-demo-iac-kargo"
}

variable "kargo_instance_version" {
  description = "The version of the Kargo instance to create or update."
  type        = string
  default     = "v1.10.1-ak.0"
}
variable "kargo_agent_version" {
  description = "The version of the Kargo agent to create or update."
  type        = string
  default     = "0.5.88"
}

variable "kargo_agent_size" {
  description = "Size of the Kargo agent"
  type        = string
  default     = "small"
}

variable "argo_admin_password" {
  description = "The password for the ArgoCD admin user."
  type        = string
  sensitive   = true
}

variable "MS_OAUTH_CLIENT_ID" {
  sensitive = true
}

variable "MS_OAUTH_CLIENT_SECRET" {
  sensitive = true
}

variable "MS_OAUTH_TENANT_ID" {
  sensitive = true
}