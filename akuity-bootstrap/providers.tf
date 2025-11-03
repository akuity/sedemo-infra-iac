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
  }
}

provider "akp" {
  org_name = "demo"
}

