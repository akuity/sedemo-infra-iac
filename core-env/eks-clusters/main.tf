module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.primary_cluster_name}-vpc"
  cidr = "10.0.0.0/16"
  azs  = formatlist("${data.aws_region.current.name}%s", ["a", "b"])
  #private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.4.0/24", "10.0.5.0/24"]
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
  source             = "terraform-aws-modules/eks/aws"
  version            = "~> 21.8.0"
  name               = var.primary_cluster_name
  kubernetes_version = 1.34

  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.public_subnets
  endpoint_public_access  = true
  endpoint_private_access = true

  # use pod-identity OR irsa, not both
  enable_irsa = true

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
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
      principal_arn = "arn:aws:iam::218691292270:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_AdministratorAccess_e2e980dbad09a8b6"
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

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  create_namespace = true
  namespace        = var.ingress_namespace
  values = [
    file("${path.module}/nginx-helm/values.yaml")
  ]
  depends_on = [module.eks]
}

# the helm chart above will implore AWS to create an ELB. We'll need it's name for the A record below.
data "aws_elb" "nginx_ingress" {
  name = substr(data.kubernetes_service_v1.nginx_ingress.status.0.load_balancer.0.ingress.0.hostname, 0, 32)

  depends_on = [
    helm_release.nginx_ingress
  ]
}

resource "aws_route53_record" "landing_global_record" {
  zone_id = data.aws_route53_zone.root_demo_domain_zone.id
  name    = data.aws_route53_zone.root_demo_domain_zone.name
  type    = "A"

  # Using alias gives us health checks without explicit definition of 'HealthCheck'
  alias {
    name                   = data.kubernetes_service_v1.nginx_ingress.status.0.load_balancer.0.ingress.0.hostname
    zone_id                = data.aws_elb.nginx_ingress.zone_id
    evaluate_target_health = true
  }

  weighted_routing_policy {
    weight = 100 #every region has equal weight, failover based on alias health check is all we rely on
  }

  set_identifier = var.primary_cluster_name

  depends_on = [helm_release.nginx_ingress]
}

resource "aws_route53_record" "records" {
  for_each = toset([
    "*."
  ])

  zone_id = data.aws_route53_zone.root_demo_domain_zone.id
  name    = each.key
  type    = "CNAME"
  ttl     = 5

  records    = [data.kubernetes_service_v1.nginx_ingress.status.0.load_balancer.0.ingress.0.hostname]
  depends_on = [helm_release.nginx_ingress]
}
