terraform {
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
    config_path = "~/.kube/config"
  }
}