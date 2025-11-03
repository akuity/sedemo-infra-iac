
# create or update an AKP (ArgoCD) instance.
resource "akp_instance" "se-demo-iac" {
  name = var.akp_instance_name
  argocd = {
    "spec" = {
      "instance_spec" = {
        declarative_management_enabled = true
        application_set_extension = {
          enabled = true
        }
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
      version = var.kargo_instance_version

      kargo_instance_spec = {
        gc_config = {
          max_retained_freight       = 20
          max_retained_promotions    = 20
          min_freight_deletion_age   = 1209600
          min_promotion_deletion_age = 1209600
        }

      }
    }
  }
  kargo_cm = {
    adminAccountEnabled  = "true"
    adminAccountTokenTtl = "24h"
  }
  kargo_secret = {
    adminAccountPasswordHash = bcrypt(var.argo_admin_password)
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
  depends_on = [akp_kargo_instance.kargo-instance]
}



# Register primary cluster with ArgoCD
resource "akp_cluster" "eks-cluster" {
  instance_id = akp_instance.se-demo-iac.id
  kube_config = {
    host                   = data.terraform_remote_state.eks_clusters.outputs.primary_cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks_clusters.outputs.primary_cluster_ca)
    exec = {
      api_version = "client.authentication.k8s.io/v1"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks_clusters.outputs.primary_cluster_name]
      command     = "aws"
      env = {
        AWS_REGION = "us-west-2"
      }
    }

  }

  name      = data.terraform_remote_state.eks_clusters.outputs.primary_cluster_name
  namespace = "akuity"
  spec = {
    data = {
      size = "small"
    }
  }
  depends_on = [akp_instance.se-demo-iac]
}

# register the Kargo cluster with ArgoCD, so we can declaratively manage Kargo projects from ArgoCD
resource "akp_cluster" "kargo-cluster" {
  instance_id = akp_instance.se-demo-iac.id

  #TODO: this shoudl be provisioned EKS cluster
  name      = "kargo"
  namespace = "akuity"
  spec = {
    data = {
      direct_cluster_spec = {
        kargo_instance_id = akp_kargo_instance.kargo-instance.id
        cluster_type      = "kargo"
      }
      size = "small"
    }
  }
  depends_on = [akp_kargo_instance.kargo-instance, akp_instance.se-demo-iac]
}

