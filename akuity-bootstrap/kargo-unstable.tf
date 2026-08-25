###################################################
# Secondary Kargo Instance for SE Team demos, uses unstable/nightly Kargo version for testing new features
##################################################

locals {
  kargo_unstable_custom_url = "${var.kargo_instance_name}-unstable.${data.terraform_remote_state.eks_clusters.outputs.demo_domain}"
}

resource "akp_kargo_instance" "kargo-unstable-instance" {
  name      = "${var.kargo_instance_name}-unstable"
  workspace = "default"
  kargo = {
    spec = {
      version   = "unstable"
      fqdn      = local.kargo_unstable_custom_url
      subdomain = "" #must be empty for fqdn 
      kargo_instance_spec = {
        default_shard_agent = "" # explicitly clear stale agent reference
        gc_config = {
          max_retained_freight       = 20
          max_retained_promotions    = 20
          min_freight_deletion_age   = 1209600
          min_promotion_deletion_age = 1209600
        }
        global_credentials_ns = [
          "kargo-secrets-namespace"
        ]
      }
      oidc_config = {
        enabled     = true
        dex_enabled = true
        dex_config  = <<-EOF
        connectors:
        - type: microsoft
          # Required field for connector id.
          id: microsoft
          # Required field for connector name.
          name: Microsoft
          config:
            # client ID is for the OAuth application registered in Azure AD, not the id of the secret.
            clientID: ${var.MS_OAUTH_CLIENT_ID}
            # value of a secret created in Azure AD for the OAuth application.
            clientSecret: '$msClientSecret'
            redirectURI: https://${local.kargo_unstable_custom_url}/dex/callback
            tenant: ${var.MS_OAUTH_TENANT_ID}
        EOF
        # this doesnt quite work
        #dex_secret = {
        #  GITHUB_CLIENT_SECRET = var.GH_OAUTH_CLIENT_SECRET_KARGO
        #}
        dex_config_secret = {
          "msClientSecret" = var.MS_OAUTH_CLIENT_SECRET
        }
        admin_account = {
          claims = {
            groups = {
              values = ["sedemo-admin"]
            }
          }
        }
        viewer_account = {
          claims = {
          }
        }
        user_account = {
          claims = {
            groups = {
              values = ["sedemo-user", "Akuity"]
            }
          }
        }
        project_creator_account = {
          claims = {
          }
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
  lifecycle {
    ignore_changes = [kargo_secret]
  }
}


# Default Agent for Kargo Instance runs on Akuity Control Plane
resource "akp_kargo_agent" "kargo-unstable-agent" {
  instance_id                 = akp_kargo_instance.kargo-unstable-instance.id
  workspace                   = "default"
  name                        = "sedemo-managed"
  namespace                   = "akuity"
  reapply_manifests_on_update = true
  spec = {
    description = "iac managed kargo agent for SE Team demos"
    data = {
      akuity_managed = true
      remote_argocd  = akp_instance.se-demo-iac.id # pulled from resource above
    }
  }
  depends_on = [akp_kargo_instance.kargo-unstable-instance]
  lifecycle {
    ignore_changes = [spec.data.target_version]
  }
}

# Set the akuity hosted control plane agent as primary instance default.
resource "akp_kargo_default_shard_agent" "unstable_default_shard_agent" {
  kargo_instance_id = akp_kargo_instance.kargo-unstable-instance.id
  agent_id          = akp_kargo_agent.kargo-unstable-agent.id
  depends_on        = [akp_kargo_instance.kargo-unstable-instance]
}


# register the Akuity Kargo cluster with ArgoCD, so we can declaratively manage Kargo projects from ArgoCD
resource "akp_cluster" "unstable-kargo-cluster" {
  instance_id = akp_instance.se-demo-iac.id

  #TODO: this shoudl be provisioned EKS cluster
  name      = "kargo-unstable"
  namespace = "akuity"
  spec = {
    data = {
      direct_cluster_spec = {
        kargo_instance_id = akp_kargo_instance.kargo-unstable-instance.id
        cluster_type      = "kargo"
      }
      size = "small"
    }
  }
  depends_on = [akp_kargo_instance.kargo-unstable-instance, akp_instance.se-demo-iac]
}


##################################################
# Custom vanity Domains for Kargo and Argo CD.
##################################################

resource "aws_route53_record" "unstable_kargo_custom_domain" {

  zone_id = data.terraform_remote_state.eks_clusters.outputs.root_zone_id
  name    = local.kargo_custom_url
  type    = "CNAME"
  ttl     = 5

  records    = ["${akp_kargo_instance.kargo-unstable-instance.id}.kargo.akuity.cloud"]
  depends_on = [akp_instance.se-demo-iac]
}
