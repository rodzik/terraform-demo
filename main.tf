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

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = "demodb"

  engine            = "postgres"
  engine_version    = "13.4"
  instance_class    = "db.t3.micro"
  allocated_storage = 5

  name     = "${var.app_name}db"
  username = "demoapp"
  password = "ThisIsSomeSickProtection"
  port     = "5432"

  iam_database_authentication_enabled = true
  vpc_security_group_ids = [module.vpc.default_security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  tags = {
    Name = "${var.app_name}-rds"
  }

  subnet_ids = module.vpc.database_subnets
  db_subnet_group_name = module.vpc.database_subnet_group_name

  deletion_protection = true

  create_db_option_group = false
  create_db_parameter_group = false
}

module "demo-webserver" {
  source = "./modules/webserver"
  vpc_id = module.vpc.vpc_id
  my_ip = var.my_ip
  app_name = var.app_name
  public_key_location = var.public_key_location
  instance_type = var.instance_type
  subnet_id = module.vpc.public_subnets[0]
  avail_zone = var.azs[0]
  image_name = "amzn2-ami-hvm-*-x86_64-gp2"
}
