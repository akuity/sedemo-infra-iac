
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
                # OOM-Killed Runbook

                ## Procedure

                Follow these steps precisely.

                ### Triage the Incident
                - First, do the initial triage and collect the basic information to understand the incident.
                - Next, send a single Slack notification with the link to the conversation to channel "#incidents" and a formatted summary of the incident details. 

                ### Plan Remediation
                - Next, devise a plan to remediate the incident according to the runbook actions defined. Don't apply any patches automatically.
                - Send a single Slack notification with your findings and planned remediation. Ask for approval before proceeding.
                - "After summarizing findings, always send the proposed remediation and approval prompt to the same Slack thread where triage notification was posted."

                ### Take Action
                - Once approval is provided, proceed applying the planned remediation.
                - Monitor the result of your remediation.

                ### Resolve Incident
                - If the app is stable, then you can close the incident automatically. You do not need confirmtation to close the incident.

                ## General Guidance

                - If you get stuck, send a Slack message again and mention that you need help.
                - Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.
                - You do not need to include every thought when sending to slack, only send summaries or when prompting for user action. 
                - "After summarizing findings, always send the proposed remediation and approval prompt to the same Slack thread where triage notification was posted.This should be it's own message to ensure prompt user attention."

                ## Action: Out of memory

                **Symptoms**: 
                - Pod unexpectedly dies with \`OOMKilled\` status.
                - Pod stuck in CrashLoopBackOff status
                - Frequent OOM kills (Out of Memory) in logs
                - Deployment or pod status "Degraded", "Exceeded progress deadline"

                **Root cause**: The pod is consuming more memory than the available memory.

                **Solution**:

                * Temporary increase the memory limit of the pod automatically
                * Increase the memory limit with the 50 Mb increment until the pod is stable.
                * Once stable, resolve the incident
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
    ignore_changes = [kargo.spec.version,kargo_secret]
  }
}



resource "akp_kargo_agent" "kargo-agent" {
  instance_id = akp_kargo_instance.kargo-instance.id
  workspace   = "default"
  name        = "sedemo-managed"
  namespace   = "akuity"
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
      # This section customizes the Kargo controller to use a specific namespace for global credentials
      # That namespace contains our secrets created by ESO (see platform repo)
      kustomization = <<-EOT
      apiVersion: kustomize.config.k8s.io/v1beta1
      kind: Kustomization
      patches:
      - patch: |-
          - op: replace
            path: /data/GLOBAL_CREDENTIALS_NAMESPACES
            value: kargo-secrets-namespace
        target:
          kind: ConfigMap
          name: kargo-controller
      resources:
      - cm.yaml
      EOT
    }
  }
  depends_on = [akp_kargo_instance.kargo-instance]
}


resource "akp_kargo_default_shard_agent" "default_shard_agent" {
  kargo_instance_id = akp_kargo_instance.kargo-instance.id
  agent_id          = akp_kargo_agent.local-kargo-agent.id
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
      size = "medium"
      kustomization = file("${path.module}/templates/argo-cluster-kustomization.yaml")
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
