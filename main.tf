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

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.app_name}"
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.pub_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ecs_sg" {
    vpc_id      = aws_vpc.vpc.id

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "rdc_sg" {
    vpc_id      = aws_vpc.vpc.id

    ingress {
        protocol        = "tcp"
        from_port       = 5432
        to_port         = 5432
        cidr_blocks     = ["0.0.0.0/0"]
        security_groups = [aws_security_group.ecs_sg.id]
    }

    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}
