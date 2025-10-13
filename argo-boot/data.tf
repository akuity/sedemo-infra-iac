# This file lets us read previously created AKP instances.
# We need this to get the instance ID of the AKP instance created in the akuity

#TODO: replace with s3 remote state once we have AWS access
data "terraform_remote_state" "akuity_boot" {
  backend = "local"
  config = {
    path = "../akuity-boot/terraform.tfstate"
  }
}


