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
    name      = "ingress-nginx"
    namespace = var.ingress_namespace
  }

  depends_on = [
    helm_release.nginx_ingress
  ]
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}