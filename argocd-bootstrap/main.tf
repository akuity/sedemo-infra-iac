resource "argocd_project" "projects" {
  for_each = var.project_spaces
  metadata {
    name      = each.key
    namespace = "argocd"
  }

  spec {
    description  = each.value.description
    source_repos = ["*"]
    dynamic "destination" {
      for_each = each.value.destinations
      iterator = DESTINATION
      content {
        name      = DESTINATION.value.name
        namespace = DESTINATION.value.namespace
        server    = "*"
      }
    }
    dynamic "cluster_resource_whitelist" {
      for_each = each.value.cluster-allows
      iterator = ALLOW
      content {
        group = ALLOW.value.group
        kind  = ALLOW.value.kind
      }
    }

  }
}




# Our app of apps that bootstraps the Platform team's setup.
resource "argocd_application" "app-of-apps" {
  metadata {
    name      = "app-of-apps"
    namespace = "argocd"
    labels = {
      cluster = "in-cluster"
    }
  }

  spec {
    destination {
      name = "in-cluster"
    }

    source {
      repo_url = var.source_repo_url
      path     = var.source_directory_path
      directory {
        recurse = var.source_directory_recursive
      }
    }
  }
  depends_on = [argocd_project.projects]
}


resource "argocd_application" "app-of-components" {
  metadata {
    name      = "app-of-components"
    namespace = "argocd"
    labels = {
      cluster = "in-cluster"
    }
  }

  spec {
    destination {
      name = "in-cluster"
    }
    project = "components"

    source {
      repo_url = var.source_repo_url
      path     = "components/declarations"
      directory {
        recurse = var.source_directory_recursive
      }
    }
  }
  depends_on = [argocd_project.projects]

}


resource "argocd_application" "templated-apps" {
  metadata {
    name      = "templated-apps"
    namespace = "argocd"
    labels = {
      cluster = "in-cluster"
    }
  }

  spec {
    destination {
      name = "in-cluster"
    }
    project = "templated-apps"

    source {
      repo_url = var.source_repo_url
      path     = "templated_teams"
      directory {
        recurse = false
      }
    }
  }
  depends_on = [argocd_project.projects]

}


resource "argocd_application" "app-of-kargo" {
  metadata {
    name      = "app-of-kargo"
    namespace = "argocd"
    labels = {
      cluster = "in-cluster"
    }
  }

  spec {
    destination {
      name = "in-cluster"
    }
    project = "kargo"

    source {
      repo_url = var.source_repo_url
      path     = "kargo"
      directory {
        recurse = false
      }
    }

    # sync_policy {
    #   automated {
    #     prune     = true
    #     self_heal = true

    #   }
    # }
  }

  depends_on = [argocd_project.projects]
}
