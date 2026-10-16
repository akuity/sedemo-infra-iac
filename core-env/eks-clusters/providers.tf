provider "aws" {
  default_tags {
    tags = var.common_tags
  }
  region = "us-west-2"
}


terraform {
  backend "s3" {
    bucket       = "arad-tf-state-files"
    region       = "us-west-2"
    key          = "cluster-${var.primary_cluster_name}/terraform.tfstate"
    use_lockfile = true
  }
  required_providers {
    # See provider "helm" below.
    helm = {
      source = "hashicorp/helm"
    }
  }
}

# Only used to refresh the helm_release state that the removed blocks in main.tf
# forget (nothing is installed). Drop this, the required_providers entry and the
# removed blocks once this has been applied.
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}
