
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

    # sync_policy {
    #   automated {
    #     prune     = true
    #     self_heal = true

    #   }
    # }
  }

}
