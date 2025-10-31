module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name                 = var.primary_cluster_name
  cidr                 = "10.0.0.0/16"
  azs                  = formatlist("${data.aws_region.current.name}%s", ["a", "b"])
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  manage_default_network_acl = false #added to avoid bug in v5.0.0

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
  source             = "terraform-aws-modules/eks/aws"
  version            = "~> 21.0"
  name               = var.primary_cluster_name
  kubernetes_version = 1.33
  # The OIDC provider for EKS cluster access via SSO is created in the global infra TF plan
  # enable_irsa creates a separate OIDC provider used solely for IRSA (IAM Roles for K8s Service Accounts)
  enable_irsa                              = true
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.public_subnets
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled = false
  }

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }
  #   eks_managed_node_group_defaults = {
  #     tags           = var.common_tags
  #   }
  tags = var.common_tags

  eks_managed_node_groups = {
    default = {
      name                 = "${var.primary_cluster_name}-ng-1"
      launch_template_name = "${var.primary_cluster_name}-launch-template"
      desired_size         = var.primary_cluser_node_count
      instance_types       = [var.primary_cluser_node_type]
      force_update_version = true
      # The role created by the Terraform module already has the cluster-specific attributes
      # Setting this to false ensures that the name_prefix conforms to the limits set by AWS
      iam_role_use_name_prefix = false
      # Add additional EBS CSI Driver Policy to the Nodegroup IAM role
      # https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEBSCSIDriverPolicy.html
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = "50"
            volume_type           = "gp2"
            encrypted             = false
            delete_on_termination = true
          }
        }
      }

      ## Explicitly set Instance Metadata Options for Nodegroup EC2 instances
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 10
        instance_metadata_tags      = "enabled"
      }


    }
  }


  # Allow kubectl access via AWS SSO credentials
  access_entries = {
    pipeline_access = {
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
  }
}


resource "kubernetes_storage_class" "expandable" {
  metadata {
    name = "default-gp2"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner    = "kubernetes.io/aws-ebs"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = "true"
  parameters = {
    type = "gp2"
  }
  depends_on = [module.eks]
}

# Expose the cluster to internet via custom domain

import {
    to= aws_route53_zone.demo_domain
    id="Z01905343OT8D9ZSW46CJ"
}

resource "aws_route53_zone" "demo_domain" {
  name    = var.root_domain_name
  comment = "Please contact eddie.webbinaro@akuity.io with questions"
  tags = {
    "Owner" = var.common_tags.owner
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  create_namespace = true
  namespace        = "ingress-nginx"
  values = [
    file("${path.module}/nginx-helm/values.yaml")
  ]
}

resource "aws_route53_record" "records" {
  for_each = toset([
    "*."
  ])

  zone_id = aws_route53_zone.demo_domain.id
  name    = each.key
  type    = "CNAME"
  ttl     = 5

  records    = [data.kubernetes_service_v1.nginx_ingress.status.0.load_balancer.0.ingress.0.hostname]
  depends_on = [helm_release.nginx_ingress]
}
