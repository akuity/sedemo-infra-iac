terraform {
  backend "s3" {
    bucket       = "arad-tf-state-files"
    region       = "us-west-2"
    key          = "akuity-${var.akp_instance_name}/terraform.tfstate"
    use_lockfile = true
  }
  required_providers {
    akp = {
      source = "akuity/akp"
    }
    argocd = {
      source = "argoproj-labs/argocd"
    }
  }
}

provider "akp" {
  org_name = "demo"
}


provider "argocd" {
  # this depends on AKP creation
  server_addr = "${akp_instance.se-demo-iac.argocd.spec.instance_spec.subdomain}.cd.akuity.cloud"
  username    = "admin"
  password    = var.argo_admin_password
}

provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.primary_cluster.module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.primary_cluster.module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.primary_cluster.module.eks.cluster_name]
      command     = "aws"
    }
  }
}