data "terraform_remote_state" "eks_clusters" {
  backend = "s3"

  config = {
    bucket = "arad-tf-state-files"
    region = "us-west-2"
    key    = "cluster-sedemo-primary/terraform.tfstate"
  }
}

data "terraform_remote_state" "akuity_platform" {
  backend = "s3"

  config = {
    bucket = "arad-tf-state-files"
    region = "us-west-2"
    key    = "akuity-se-demo-iac/terraform.tfstate"
  }
}

#debug
output "argo_cd_url" {
  value = data.terraform_remote_state.akuity_platform.outputs.argo_server_url
}

output "argo_cd_password" {
  value     = data.terraform_remote_state.akuity_platform.outputs.argo_admin_password
  sensitive = false
}