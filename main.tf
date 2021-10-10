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

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
      Name = "${var.app_name}"
    }
}

resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.vpc.id
    tags = {
      Name = "${var.app_name}"
    }
}

resource "aws_subnet" "pub_subnet" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = "10.0.10.0/24"
    tags = {
      Name = "${var.app_name}"
    }
}
