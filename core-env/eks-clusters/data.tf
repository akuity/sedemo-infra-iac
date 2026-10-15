data "terraform_remote_state" "arad_aws_state" {
  backend = "s3"

  config = {
    bucket = "arad-tf-state-files"
    region = "us-west-2"
    key    = "se-team-aws-setup/terraform.tfstate"
  }
}

data "kubernetes_service_v1" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = var.ingress_namespace
  }

  depends_on = [
    helm_release.nginx_ingress
  ]
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret_version" "twingate" {
  secret_id = var.twingate_secret_arn
}

data "aws_secretsmanager_secret_version" "twingate_api_token" {
  secret_id = var.twingate_api_token_secret_id
}

locals {
  twingate_secret = jsondecode(data.aws_secretsmanager_secret_version.twingate.secret_string)
}

data "twingate_remote_networks" "sedemo" {
  name = var.twingate_remote_network_name
}

data "twingate_service_accounts" "gha" {
  name = var.twingate_gha_service_account_name
}

# Skipped when no groups are configured: an empty name_in filter returns every group.
data "twingate_groups" "eks_api" {
  count   = length(var.twingate_eks_api_groups) > 0 ? 1 : 0
  name_in = var.twingate_eks_api_groups
}
