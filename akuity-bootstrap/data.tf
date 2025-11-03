data "terraform_remote_state" "eks_clusters" {
  backend = "s3"

  config = {
    bucket = "arad-tf-state-files"
    region = "us-west-2"
    key    = "cluster-sedemo-primary/terraform.tfstate"
  }
}