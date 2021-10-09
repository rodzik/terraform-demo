terraform {
    backend "s3" {
        bucket = "terraform-state-bucket-jr"
        key = "terraform-state-bucket-jr/state.tfstate"
        region = "eu-central-1"
    }
}

provider "aws" {
  region = "eu-central-1"
}
