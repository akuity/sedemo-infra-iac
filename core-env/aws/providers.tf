provider "aws" {
  default_tags {
    tags = var.common_tags
  }
  region = "us-west-2"
}


terraform {
  backend "s3" {
    bucket         = "arad-tf-state-files"
    region         = "us-west-2"
    key            = "se-team-primary-cluster/terraform.tfstate"
    use_lockfile = true
  }
}