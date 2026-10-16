module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.primary_cluster_name}-vpc"
  cidr = "10.0.0.0/16"
  azs  = formatlist("${data.aws_region.current.region}%s", ["a", "b"])
  #private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  #public_subnet_assign_
  #enable_nat_gateway = true
  #single_nat_gateway = true
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  #enable_ipv6 = true

  tags = merge(var.common_tags, {
    "kubernetes.io/cluster/${var.primary_cluster_name}" = "shared"
  })

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.primary_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                            = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.primary_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"                   = "1"
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.25.0"
  name    = var.primary_cluster_name
  # WARNING: EKS based k8s upgrades may only be 1 minor version from current.
  # So to move from 1.36 to 1.38 you must first upgrade to 1.37, then 1.38.
  # See https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html
  kubernetes_version = 1.36

  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.public_subnets
  endpoint_public_access  = var.eks_endpoint_public_access
  endpoint_private_access = true

  # use pod-identity OR irsa, not both
  enable_irsa = true

  addons = {
    coredns = {
      configuration_values = jsonencode({
        resources = {
          requests = {
            cpu = "50m"
          }
        }
      })
    }
    kube-proxy = {
      configuration_values = jsonencode({
        resources = {
          requests = {
            cpu = "50m"
          }
        }
    }) }
    vpc-cni = {
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  tags = var.common_tags
  eks_managed_node_groups = {
    default = {
      #ami_type = "AL2023_ARM_64_STANDARD"
      ami_type = "AL2023_x86_64_STANDARD"
      tags     = var.common_tags
      #launch_template_name = "${var.primary_cluster_name}-launch-template"
      desired_size   = var.primary_cluser_node_count
      instance_types = [var.primary_cluser_node_type]
      disk_size      = 50

      ## Explicitly set Instance Metadata Options for Nodegroup EC2 instances
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 10
        instance_metadata_tags      = "enabled"
      }

      iam_role_attach_cni_policy = true
    }


  }
  # Allow kubectl access via AWS SSO credentials
  access_entries = {
    # pipeline access to k8s
    pipeline_eks_access = {
      principal_arn = data.terraform_remote_state.arad_aws_state.outputs.demo_pipeline_role_arn
      policy_associations = {
        admin_policy = {
          ### https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
        namespace_policy = {
          ### https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["default", "kube-system", "*"]
          }
        }
      }
    }
    # team operator role
    fieldeng_eks_access = {
      principal_arn = data.terraform_remote_state.arad_aws_state.outputs.demo_operator_role_arn
      policy_associations = {
        admin_policy = {
          ### https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
        namespace_policy = {
          ### https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["default", "kube-system", "*"]
          }
        }
      }
    }
    # IT assigned SSO role
    sso_admin_access = {
      principal_arn = "arn:aws:iam::218691292270:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_PowerUserAccess_8de5f1934424d9c6"
      policy_associations = {
        admin_policy = {
          ### https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
        namespace_policy = {
          ### https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["default", "kube-system", "*"]
          }
        }
      }
    }
  }
}

# We don't import/manage the root domainzone, only the sub-domains or records we hang off it.
data "aws_route53_zone" "root_demo_domain_zone" {
  name = var.root_domain_name
}

# ingress-nginx and its Route53 records moved to sedemo-platform (Argo CD +
# external-dns, sedemo-platform#184) so this module never needs the cluster API.
# Forget the release instead of uninstalling it: Argo CD adopts the running
# controller and its ELB. The two records are deleted; external-dns recreates them.
removed {
  from = helm_release.nginx_ingress
  lifecycle {
    destroy = false
  }
}

#
# ESO - External Secrets Operator
#. Creates a policy with access to secrets,
#.   a role granting assume permissions from cluster OIDC provider, and a policy attachment connecting them.
#.   Service Accounts must specify the role's ARN to gain access. See platform repo's /secrets path

resource "aws_iam_policy" "irsa_policy_eso" {
  name = "${var.primary_cluster_name}-irsa-policy-external-secrets"

  description = "Policy allowing ServiceAccount access to ESO."

  policy = templatefile(
    "${path.module}/templates/secrets_policy.json.tpl",
    {
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.id,
    }
  )

  tags = var.common_tags

}

resource "aws_iam_role" "eks_service_account_role" {
  name = "${var.primary_cluster_name}-irsa-role-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        # Condition = {
        #   StringEquals = {
        #     "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:my-namespace:my-service-account"
        #   }
        # }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "irsa_secrets" {
  role       = aws_iam_role.eks_service_account_role.name
  policy_arn = aws_iam_policy.irsa_policy_eso.arn
}




# resource "aws_iam_role" "eks_service_account_role_for_kargo_steps" {
#   name = "${var.primary_cluster_name}-irsa-role-kargo-steps"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}"
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringLike = {
#             "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com",
#             "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:akuity:*",

#           }
#         }
#       }
#     ]
#   })
# }


# resource "aws_iam_role_policy_attachment" "irsa_kargo_steps" {
#   role       = aws_iam_role.eks_service_account_role_for_kargo_steps.name
#   policy_arn = aws_iam_policy.irsa_policy_eso.arn
# }


# arn:aws:sts::218691292270:assumed-role/default-eks-node-group-20251111192150921200000002/i-0121fb11f5ec3bd40

#
# Twingate connector moved to sedemo-platform (Argo CD, tokens via ESO). Forget
# the release instead of uninstalling it so the connector keeps running.
#
removed {
  from = helm_release.twingate_connector
  lifecycle {
    destroy = false
  }
}

#
# external-dns: manages akpdemoapps.link records from the ingress-nginx Service
# (deployed by sedemo-platform). Only the AWS side lives here.
#
resource "aws_iam_policy" "irsa_policy_external_dns" {
  name        = "${var.primary_cluster_name}-irsa-policy-external-dns"
  description = "Policy allowing external-dns to manage records in the demo domain zone."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = [data.aws_route53_zone.root_demo_domain_zone.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResources",
        ]
        Resource = ["*"]
      },
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role" "external_dns" {
  name = "${var.primary_cluster_name}-irsa-role-external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:external-dns:external-dns"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.irsa_policy_external_dns.arn
}
