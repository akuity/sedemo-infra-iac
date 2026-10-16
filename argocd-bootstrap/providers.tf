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
  server_addr = data.terraform_remote_state.akuity_platform.outputs.argo_custom_url
  username    = "admin"
  password    = data.terraform_remote_state.akuity_platform.outputs.argo_admin_password
}
