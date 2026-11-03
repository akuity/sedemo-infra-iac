###################################################
# Primary SE Demo ArgoCD instance, with Kargo integration and AI runbooks for incident management.
##################################################
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

        # Akuity Intelligence (AI SRE) configuration, mirrored from the live
        # instance. The provider only reads this under kube_vision_config; an
        # ai_config block directly under instance_spec is silently ignored.
        # Runbook content lives in ./runbooks.
        #
        # KNOWN PROVIDER ISSUE (akp 0.10.1-rc.1 and 0.18.0): for an existing
        # instance the plan always proposes the server's current value for this
        # whole block, so edits here are NOT applied. Make changes in the Akuity
        # UI, then mirror them here to keep this file accurate.
        kube_vision_config = {
          cve_scan_config = {
            scan_enabled    = true
            rescan_interval = "168h"
          }
          ai_config = {
            argocd_slack_channels = ["incidents"]
            runbooks = [
              {
                name                = "pod-oom"
                content             = file("${path.module}/runbooks/pod-oom.md")
                slack_channel_names = ["incidents"]
                applied_to = {
                  argocd_applications = ["demo-intelligence-prod-oom"]
                  k8s_namespaces      = ["*"]
                  clusters            = ["*"]
                }
              },
              {
                name                = "pod-health-issues"
                content             = file("${path.module}/runbooks/pod-health-issues.md")
                slack_channel_names = ["incidents"]
              },
              {
                name    = "argocd-app-degraded"
                content = file("${path.module}/runbooks/argocd-app-degraded.md")
              },
              {
                name    = "argocd-app-out-of-sync"
                content = file("${path.module}/runbooks/argocd-app-out-of-sync.md")
              },
              {
                name    = "argocd-app-sync-failure"
                content = file("${path.module}/runbooks/argocd-app-sync-failure.md")
              },
              {
                name    = "pod-pending-scheduling"
                content = file("${path.module}/runbooks/pod-pending-scheduling.md")
              },
              {
                name    = "pvc-binding-failure"
                content = file("${path.module}/runbooks/pvc-binding-failure.md")
              },
              {
                name    = "time-drift"
                content = file("${path.module}/runbooks/time-drift.md")
              },
              {
                name    = "cni-networking"
                content = file("${path.module}/runbooks/cni-networking.md")
              },
              {
                name    = "service-connectivity"
                content = file("${path.module}/runbooks/service-connectivity.md")
              },
              {
                name    = "image-pull-failure"
                content = file("${path.module}/runbooks/image-pull-failure.md")
              },
              {
                name    = "pod-evictions"
                content = file("${path.module}/runbooks/pod-evictions.md")
              },
              {
                name    = "rbac-denials"
                content = file("${path.module}/runbooks/rbac-denials.md")
              },
              {
                name                = "pod-crashloop"
                content             = file("${path.module}/runbooks/pod-crashloop.md")
                slack_channel_names = ["incidents"]
                applied_to = {
                  argocd_applications = ["demo-intelligence-prod-crashloop"]
                  k8s_namespaces      = ["*"]
                  clusters            = ["*"]
                }
              }
            ]
            incidents = {
              triggers = [
                {
                  # Scoped by app name: an argocd_applications of "*" matched every
                  # Degraded app on the instance regardless of k8s_namespaces.
                  argocd_applications = ["demo-intelligence-*"]
                  clusters            = ["*"]
                }
              ]
              # Explicitly empty: incidents are created per Argo CD application, so
              # the OOM and crashloop demos in demo-intelligence stay independent.
              # (Omitting grouping keeps whatever is set on the server.)
              grouping = {
                k8s_namespaces           = []
                argocd_application_names = []
              }
              investigation_approval = {
                scopes = [
                  {
                    argocd_applications       = ["*"]
                    k8s_namespaces            = ["*"]
                    clusters                  = ["*"]
                    consecutive_auto_closures = 1
                  }
                ]
              }
            }
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
    "accounts.admin"          = "login"
    "accounts.github-actions" = "apiKey"
    "dex.config"              = <<-EOF
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
          clientSecret: $dex.microsoft.clientSecret
          redirectURI: https://${local.argo_custom_url}/api/dex/callback
          tenant: ${var.MS_OAUTH_TENANT_ID}
      EOF
    # Settings below were added outside Terraform (UI/API) and are captured
    # here so applies stop deleting them.
    "accounts.admin.enabled"                                         = "true"
    "accounts.finops"                                                = "apiKey,login"
    "accounts.finops.enabled"                                        = "true"
    "accounts.github-actions.enabled"                                = "true"
    "exec.enabled"                                                   = "false"
    "ga.anonymizeusers"                                              = "false"
    "helm.enabled"                                                   = "true"
    "kustomize.enabled"                                              = "true"
    "resource.customizations.actions.argoproj.io_ApplicationSet"     = chomp(file("${path.module}/argocd-cm/applicationset-refresh-action.yaml"))
    "resource.customizations.health.argoproj.io_Application"         = chomp(file("${path.module}/argocd-cm/application-health.lua"))
    "resource.customizations.useOpenLibs.argoproj.io_Application"    = "false"
    "resource.customizations.useOpenLibs.argoproj.io_ApplicationSet" = "false"
    "server.rbac.log.enforce.enable"                                 = "false"
    "statusbadge.enabled"                                            = "false"
    "ui.bannerpermanent"                                             = "false"
    "users.anonymous.enabled"                                        = "false"
  }
  argocd_rbac_cm = {
    "policy.csv" = <<-EOF
      # grant platform-team full access, including platform provided read-only base permissions
      p, role:platform-team, *,*, */*, allow
      g, role:platform-team, role:readonly
      # map platform-team group to platform-team role
      g, sedemo-admin, role:platform-team
      # grant auditor-role to  readonly role
      g, sedemo-auditor, role:readonly
      # grant user-role to  readonly role
      g, sedemo-user, role:readonly
      # github-actions service account: refresh applications and applicationsets
      p, role:argocd-refresh, applications,    get, */*,  allow
      p, role:argocd-refresh, applicationsets, get, */*,  allow
      g, github-actions, role:argocd-refresh
      EOF
  }
  # Set password for `admin` user.
  argocd_secret = {
    "admin.password"             = bcrypt(var.argo_admin_password)
    "dex.microsoft.clientSecret" = var.MS_OAUTH_CLIENT_SECRET
  }
  lifecycle {
    ignore_changes = [
      argocd.spec.version,
      argocd.spec.instance_spec.kube_vision_config,
      argocd_secret
    ]
  }
}

# Primary Kargo Instance for SE Team demos
resource "akp_kargo_instance" "kargo-instance" {
  name      = var.kargo_instance_name
  workspace = "default"
  kargo = {
    spec = {
      version   = var.kargo_instance_version
      fqdn      = local.kargo_custom_url
      subdomain = "" #must be empty for fqdn 
      kargo_instance_spec = {
        default_shard_agent = "" # explicitly clear stale agent reference
        gc_config = {
          max_retained_freight       = 20
          max_retained_promotions    = 20
          min_freight_deletion_age   = 1209600
          min_promotion_deletion_age = 1209600
        }
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
            redirectURI: https://${local.kargo_custom_url}/dex/callback
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
            groups = {
              values = ["sedemo-user", "Akuity"]
            }
          }
        }
        user_account = {
          claims = {

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
    ignore_changes = [kargo.spec.version, kargo_secret]
  }
}


# Default Agent for Kargo Instance runs on Akuity Control Plane
resource "akp_kargo_agent" "kargo-agent" {
  instance_id                 = akp_kargo_instance.kargo-instance.id
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
  depends_on = [akp_kargo_instance.kargo-instance]
  lifecycle {
    ignore_changes = [spec.data.target_version]
  }
}

# import {
#   to = akp_kargo_agent.local-kargo-agent
#   id = "${akp_kargo_instance.kargo-instance.id}/sedemo-primary"
# }

# Kargo Agent on SE Primary EKS Cluster
resource "akp_kargo_agent" "local-kargo-agent" {
  instance_id = akp_kargo_instance.kargo-instance.id
  workspace   = "default"
  name        = "sedemo-primary"
  namespace   = "akuity"
  spec = {
    description = "local iac managed kargo agent for SE Team demos"
    data = {
      size           = var.kargo_agent_size
      akuity_managed = false
      remote_argocd  = akp_instance.se-demo-iac.id # pulled from resource above
    }
  }
  depends_on = [akp_kargo_instance.kargo-instance]
}

# Set the local (EKS) agent as primary instance default.
resource "akp_kargo_default_shard_agent" "default_shard_agent" {
  kargo_instance_id = akp_kargo_instance.kargo-instance.id
  agent_id          = akp_kargo_agent.local-kargo-agent.id
  depends_on        = [akp_kargo_instance.kargo-instance]
}

# Register primary cluster with ArgoCD and install Agent manifests
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
      size          = "medium"
      kustomization = file("${path.module}/templates/argo-cluster-kustomization.yaml")
    }
  }
  depends_on = [akp_instance.se-demo-iac]
}

# register the Akuity Kargo cluster with ArgoCD, so we can declaratively manage Kargo projects from ArgoCD
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


##################################################
# Custom vanity Domains for Kargo and Argo CD.
##################################################

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
