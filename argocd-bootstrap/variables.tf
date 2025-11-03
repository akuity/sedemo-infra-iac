
# APP of APP config
# This is the single root seed for all other argoCD apps.

variable "source_repo_url" {
  description = "The git URL of the repo containing the app-of-apps."
  type        = string
  default     = "https://github.com/akuity/sedemo-platform"
}

variable "source_repo_target_revision" {
  description = "The git revision (branch, tag, commit) of the repo containing the app-of-apps."
  type        = string
  default     = "HEAD"
}

variable "source_directory_recursive" {
  description = "The path within the git repo to the app-of-apps."
  type        = bool
  default     = true
}

variable "source_directory_path" {
  description = "The path within the git repo to the app-of-apps."
  type        = string
  default     = "apps"

}