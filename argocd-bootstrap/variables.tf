
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

variable "project_spaces" {
  description = "Project spaces allow apps to be logically grouped."
  type    = map(object( 
    {
      name = string
      description = string
      destinations = list(object({
        name = string
        namespace = string
      }))
      cluster-allows = list(object({
        group = string
        kind = string
      }))
    }
   ))
  default = {
    "components" = {
      "name" = "components"
      "description" = "Cluster addons, components"
      "destinations" = [{
        name = "*"
        namespace ="*"
      }]
      "cluster-allows" = [{
        group = "*"
        kind = "*"
      }]
    }

    "pattern-apps" = {
      "name" = "pattern-apps"
      "description" = "For  apps using org-wide standard ABC"
      "destinations" = [{
        name = "*"
        namespace ="*"
      }]
      "cluster-allows" = [{
        group = "*"
        kind = "Namespace"
      }]
    }

    "kargo" = {
      "name" = "kargo"
      "description" = "Kargo definitions only"
      "destinations" = [{
        name = "kargo"
        namespace ="*"
      }]
      "cluster-allows" = [{
        group = "*"
        kind = "*"
      }]
    }
    "rollouts" = {
      "name" = "rollouts"
      "description" = "Various progressive release demos"
      "destinations" = [{
        name = "*"
        namespace ="*"
      }]
      "cluster-allows" = [{
        group = "*"
        kind = "*"
      }]
    }
  }
}