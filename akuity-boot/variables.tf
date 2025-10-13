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
  default     = "v3.1.8-ak.66"
}

variable "kargo_instance_name" {
  description = "The name of the Kargo instance to create or update."
  type        = string
  default     = "se-demo-iac-kargo"
}   

variable "kargo_instance_version" {
  description = "The version of the Kargo instance to create or update."
  type        = string
  default     = "v1.7.5-ak.0"
}
variable "kargo_agent_name" {
  description = "The name of the Kargo agent to create or update."
  type        = string
  default     = "se-demo-kargo-agent"
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

variable "iac_cluster_name" {
  description = "The name of the local cluster to register with ArgoCD."
  type        = string
}

variable "source_repo_url" {
  description = "The git URL of the repo containing the app-of-apps."
  type        = string
}

variable "destination_cluster_name" {
  description = "The name of the destination cluster in ArgoCD."
  type        = string
}

variable "source_repo_target_revision" {
  description = "The git revision (branch, tag, commit) of the repo containing the app-of-apps."
  type        = string
  default     = "HEAD"

}

variable "source_directory_recursive" {
  description = "The path within the git repo to the app-of-apps."
  type        = bool
  default     = false
}

variable "source_directory_path" {
  description = "The path within the git repo to the app-of-apps."
  type        = string
  default     = "apps"

}