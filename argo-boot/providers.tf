

terraform {
  required_providers {
    argocd = {
      source = "argoproj-labs/argocd"
    }
  }
}






provider "argocd" {
  server_addr = data.terraform_remote_state.akuity_boot.outputs.argo_server_url
    username    = "admin"
    password    = data.terraform_remote_state.akuity_boot.outputs.argo_admin_password
}   