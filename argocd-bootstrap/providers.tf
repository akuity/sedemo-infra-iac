terraform {
  backend "s3" {
    bucket       = "arad-tf-state-files"
    region       = "us-west-2"
    key          = "argocd-se-demo-iac/terraform.tfstate"
    use_lockfile = true
  }
  required_providers {
    argocd = {
      source = "argoproj-labs/argocd"
    }
  }
}


provider "argocd" {
  # this depends on AKP creation
  server_addr = data.terraform_remote_state.akuity_platform.outputs.argo_server_url
  username    = "admin"
  password    = data.terraform_remote_state.akuity_platform.outputs.argo_admin_password
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