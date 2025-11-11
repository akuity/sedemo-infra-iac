
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
                  - Next, send a slack notification with the link to the conversation to channel “PLEASE REPLACE” with basic detail.
                  - Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
                  - If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
                  - If you stack send a slack message again and mention that you need help.
                  - Please ensure you send slack message with the link to the conversation, so engineer can work with you together if needed.

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
  }
  # Set password for `admin` user.
  argocd_secret = {
    "admin.password" = bcrypt(var.argo_admin_password)
  }
}

# create or update a Kargo instance.
resource "akp_kargo_instance" "kargo-instance" {
  name      = var.kargo_instance_name
  workspace = "default"
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
        global_credentials_ns = [
          "kargo-secrets-namespace"
        ]
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

# resource "aws_route53_record" "records" {

#   zone_id = data.terraform_remote_state.eks_clusters.outputs.root_zone_id
#   name    = "argo.${data.terraform_remote_state.eks_clusters.outputs.demo_domain}"
#   type    = "CNAME"
#   ttl     = 5

#   records    = [outputs.argo_server_url]
#   depends_on = [akp_instance.se-demo-iac]
# }
