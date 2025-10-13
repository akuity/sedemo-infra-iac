
# create or update an AKP (ArgoCD) instance.
resource "akp_instance" "se-demo-iac" {
  name = var.akp_instance_name
  argocd = {
    "spec" = {
      "instance_spec" = {
        "declarative_management_enabled" = true
      }
      "version" = var.akp_instance_version
    }
  }
  argocd_cm = {
    "accounts.admin" = "login"
  }
  # Set password for `admin` user.
  argocd_secret = {
    "admin.password" = bcrypt(var.argo_admin_password)
  }
}

# create or update a Kargo instance.
resource "akp_kargo_instance" "kargo-instance" {
  name = var.kargo_instance_name
  kargo = {
    spec = {
      version             = var.kargo_instance_version
      kargo_instance_spec = {}
    }
  }
}


resource "akp_kargo_agent" "kargo-agent" {
  instance_id = akp_kargo_instance.kargo-instance.id
  name        = var.kargo_agent_name
  namespace   = "kargo"
  labels = {
    "app" = "kargo"
  }
  annotations = {
    "app" = "kargo"
  }
  spec = {
    description = "iac managed kargo agent for SE Team demos"
    data = {
      size           = var.kargo_agent_size
      akuity_managed = true
      remote_argocd  = akp_instance.se-demo-iac.id # pulled from resource above
    }
  }
}


# Register local cluster with ArgoCD
resource "akp_cluster" "local-cluster" {
  instance_id = akp_instance.se-demo-iac.id
  kube_config = {
    config_context = "orbstack"
    config_path    = "~/.kube/config"
  }
  #TODO: this shoudl be provisioned EKS cluster
  name      = var.iac_cluster_name
  namespace = "akuity"
  spec = {
    data = {
      size = "small"
    }
  }
}



# Our app of apps that bootstraps the Platform team's setup.
resource "argocd_application" "app-of-apps" {
  metadata {
    name      = "app-of-apps"
    namespace = "argocd"

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

    sync_policy {
      automated {
        prune     = true
        self_heal = true

      }
    }
  }
}