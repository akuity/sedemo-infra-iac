data "terraform_remote_state" "primary_cluster" {
  backend = "s3"

  config = {
    bucket = "arad-tf-state-files"
    region = "us-west-2"
    key    = "cluster-sedemo-primary/terraform.tfstate"
  }
}