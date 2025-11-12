data "terraform_remote_state" "eks_clusters" {
  backend = "s3"

  config = {
    bucket = "arad-tf-state-files"
    region = "us-west-2"
    key    = "cluster-sedemo-primary/terraform.tfstate"
  }
}

locals {
  kargo_custom_url = "kargo.${data.terraform_remote_state.eks_clusters.outputs.demo_domain}"
  argo_custom_url  = "argo.${data.terraform_remote_state.eks_clusters.outputs.demo_domain}"
}