

# Our app of apps that bootstraps the Platform team's setup.
resource "argocd_application" "app-of-apps" {
  metadata {
    name      = "app-of-apps"
    namespace = "argocd"

  }

  spec {
    destination {
      name=       var.destination_cluster_name
    }

    source {
      repo_url        =  var.source_repo_url
      path            = var.source_directory_path
      directory {
        recurse = var.source_directory_recursive
      }
    }
  }
}