provider "aws" {
  region = "eu-central-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.app_name}-vpc"
  cidr = var.vpc_cidr_block

  azs = var.azs
  public_subnets = [var.public_subnet_cidr_block]

  create_database_subnet_group = true
  database_subnets = var.database_subnets

  tags = {
    Name = "${var.app_name}-vpc"
  }

  database_subnet_tags = {
    "Name" = "${var.app_name}-db-subnet"
  }
}
