
# create or update an AKP (ArgoCD) instance.
resource "akp_instance" "se-demo-iac" {
  name = var.akp_instance_name
  argocd = {
    "spec" = {
      "instance_spec" = {
        fqdn                           = local.argo_custom_url
        declarative_management_enabled = true
        application_set_extension = {
          enabled = true
        }
        "extensions" = [
          {
            "id"      = "argo_rollouts"
            "version" = "v0.3.7"
          }
        ]
        akuity_intelligence_extension = {
          # Enable the Akuity Intelligence Extension
          enabled = true
          # Specific users who can access AI features
          allowed_usernames = [
            "*",
          ]
          # Groups that have access to AI features
          allowed_groups = [
            "*",
          ]
          # Enable AI support engineer for advanced troubleshooting capabilities
          ai_support_engineer_enabled = true
        }

        ai_config = {
          # ArgoCD Slack service name for notifications (must match your argocd-notifications-cm config)
          #argocd_slack_service = "argo-notifications"
          # AI Runbooks - Automated troubleshooting guides that can be triggered by incidents
          # Each runbook should contain step-by-step instructions for resolving common issues
          # The AI can automatically execute or suggest these runbooks when incidents occur
          runbooks = [
            {
              name    = "oom"
              content = <<-EOF
                  ## General

                  - First, do the initial triage and collect the basic information to understand the incident.
                  - Next, work on the incident according to the runbook. Don't apply any patches automatically, ask for approval.
                  - If the app is stable, check 30 seconds later again, then you can close the incident automatically.

                  ## Out of memory

                  **Symptoms**: Pod unexpectedly dies with \`OOMKilled\` status.

                  **Root cause**: The pod is consuming more memory than the available memory.

                  **Solution**:

                  * Temporary increase the memory limit of the pod automatically
                  * Increase the memory limit with the 50 Mb increment until the pod is stable.
                EOF
              applied_to = {
                argocd_applications = ["oom-*"]
                k8s_namespaces      = ["*"]
                clusters            = ["*r"]
              }
            }
          ]

          # Incident Management Configuration
          # Defines when to trigger incidents and how to notify external systems
          incidents = {
            # Incident triggers - Define conditions that automatically create incidents
            # When these conditions are met, AI runbooks can be automatically executed
            triggers = [
              {
                argocd_applications = ["oom-dev"]
                k8s_namespaces      = ["*"]

              }
            ]

            # Webhook configurations for incident notifications
            # Define how to notify external systems (PagerDuty, Slack, Teams, etc.) when incidents occur
            # Each webhook specifies JSON paths to extract relevant information from the incident payload
            # webhooks = [
            #   {
            #     name                         = "slack-alert"
            #     description_path             = "{.body.alerts[0].annotations.description}"
            #     cluster_path                 = "{.query.clusterName}"
            #     k8s_namespace_path           = "{.body.alerts[0].labels.namespace}"
            #     argocd_application_name_path = ""
            #   }
            # ]
          }
        }
        // Control plane metrics
        metrics_ingress_username      = "user"
        metrics_ingress_password_hash = "passwordhash"
      }

      "version" = var.akp_instance_version
    }
  }
  argocd_cm = {
    "accounts.admin" = "login"
    "dex.config"     = <<-EOF
        connectors:
          - type: github
            id: github
            name: GitHub
            config:
              clientID: ${var.GH_OAUTH_CLIENT_ID}
              clientSecret: $dex.github.clientSecret
              redirectURI: https://${local.argo_custom_url}/api/dex/callback
              orgs:
              - name: akuity
              - name: akuityio
              #preferredEmailDomain: "akuity.io"
      EOF
  }
  argocd_rbac_cm = {
    "policy.csv" = <<-EOF
      p, role:org-admin, *,*, */*, allow
      p, role:sales-team, *, get, */*, allow
      g, akuity:sedemo, role:org-admin
      g, akuityio:sales, role:sales-team
      EOF
    "policy.default" = "role:readonly"
  }
  # Set password for `admin` user.
  argocd_secret = {
    "admin.password"          = bcrypt(var.argo_admin_password)
    "dex.github.clientSecret" = var.GH_OAUTH_CLIENT_SECRET
  }
}

# create or update a Kargo instance.
resource "akp_kargo_instance" "kargo-instance" {
  name      = var.kargo_instance_name
  workspace = "default"
  kargo = {
    spec = {
      version   = var.kargo_instance_version
      fqdn      = local.kargo_custom_url
      subdomain = "" #must be empty for fqdn 
      kargo_instance_spec = {
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
          - type: github
            id: github
            name: GitHub
            config:
              clientID: ${var.GH_OAUTH_CLIENT_ID_KARGO}
              clientSecret: $GITHUB_CLIENT_SECRET
              redirectURI: https://${local.kargo_custom_url}/api/dex/callback
              orgs:
              - name: akuity
              - name: akuityio
              #preferredEmailDomain: "akuity.io"
        EOF
        # this doesnt quite work
        #dex_secret = {
        #  GITHUB_CLIENT_SECRET = var.GH_OAUTH_CLIENT_SECRET_KARGO
        #}
        dex_config_secret = {
          GITHUB_CLIENT_SECRET = var.GH_OAUTH_CLIENT_SECRET_KARGO
        }
        admin_account = {
          claims = {
            groups = {
              values = ["akuity:sedemo"]
            }
          }
        }
        viewer_account = {
          claims = {
            groups = {
              values = ["akuityio:sales"]
            }
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
}


resource "akp_kargo_agent" "kargo-agent" {
  instance_id = akp_kargo_instance.kargo-instance.id
  workspace   = "default"
  name        = "default"
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

resource "aws_route53_record" "argo_custom_domain" {

  zone_id = data.terraform_remote_state.eks_clusters.outputs.root_zone_id
  name    = local.argo_custom_url
  type    = "CNAME"
  ttl     = 5

  records    = ["${akp_instance.se-demo-iac.id}.cd.akuity.cloud"]
  depends_on = [akp_instance.se-demo-iac]
}

resource "aws_route53_record" "kargo_custom_domain" {

  zone_id = data.terraform_remote_state.eks_clusters.outputs.root_zone_id
  name    = local.kargo_custom_url
  type    = "CNAME"
  ttl     = 5

  records    = ["${akp_kargo_instance.kargo-instance.id}.kargo.akuity.cloud"]
  depends_on = [akp_instance.se-demo-iac]
}
