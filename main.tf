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

resource "aws_subnet" "pub_subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "eu-central-1a"

  tags = {
    Name = "${var.app_name}"
  }
}

resource "aws_subnet" "pub_subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "eu-central-1b"

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

resource "aws_route_table_association" "route_table_association1" {
  subnet_id      = aws_subnet.pub_subnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "route_table_association2" {
  subnet_id      = aws_subnet.pub_subnet2.id
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
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 3000
        to_port         = 3000
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
      Name = "${var.app_name}-ecs-sg"
    }
}

resource "aws_security_group" "rds_sg" {
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

    tags = {
      Name = "${var.app_name}-rds-sg"
    }
}

data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

resource "aws_key_pair" "ssh-key" {
  key_name = "${var.app_name}-key-pair"
  public_key = file(var.public_key_location)
}

resource "aws_launch_configuration" "ecs_launch_config" {
    image_id             = "ami-094d4d00fd7462815"
    iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
    security_groups      = [aws_security_group.ecs_sg.id]
    user_data            = file("entrypoint.sh")
    instance_type        = "t2.micro"
    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

}

resource "aws_autoscaling_group" "failure_analysis_ecs_asg" {
    name                      = "asg"
    vpc_zone_identifier       = [aws_subnet.pub_subnet1.id, aws_subnet.pub_subnet2.id]
    launch_configuration      = aws_launch_configuration.ecs_launch_config.name

    desired_capacity          = 1
    min_size                  = 1
    max_size                  = 3
    health_check_grace_period = 300
    health_check_type         = "EC2"
}

resource "aws_db_subnet_group" "db_subnet_group" {
    subnet_ids  = [aws_subnet.pub_subnet1.id, aws_subnet.pub_subnet2.id]
}

resource "aws_db_instance" "database" {
    identifier                = "postgres"
    allocated_storage         = 5
    backup_retention_period   = 2
    backup_window             = "01:00-01:30"
    maintenance_window        = "sun:03:00-sun:03:30"
    multi_az                  = false
    engine                    = "postgres"
    engine_version            = "13.4"
    instance_class            = "db.t3.micro"
    name                      = "${var.app_name}_db"
    username                  = "username"
    password                  = "password"
    port                      = "5432"
    db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.id
    vpc_security_group_ids    = [aws_security_group.rds_sg.id, aws_security_group.ecs_sg.id]
    skip_final_snapshot       = true
    final_snapshot_identifier = "worker-final"
    publicly_accessible       = true
    deletion_protection = false
}

resource "aws_ecr_repository" "worker" {
    name  = "${var.app_name}"
}

resource "aws_ecs_cluster" "ecs_cluster" {
    name  = "my-cluster"
}

data "template_file" "task_definition_template" {
    template = file("task_definition.json.tpl")
    vars = {
      REPOSITORY_URL = replace(aws_ecr_repository.worker.repository_url, "https://", ""),
      RDS_DB_NAME = aws_db_instance.database.name,
      RDS_USERNAME = aws_db_instance.database.username,
      RDS_PASSWORD = "password",
      RDS_HOSTNAME = aws_db_instance.database.address,
      RDS_PORT = aws_db_instance.database.port,
      RDS_URL = aws_db_instance.database.endpoint
    }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = "${var.app_name}"
  container_definitions = data.template_file.task_definition_template.rendered
}

resource "aws_ecs_service" "worker" {
  name            = "${var.app_name}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.main_target_group.arn
    container_name   = "demo-web"
    container_port   = 3000
  }
}

resource "aws_lb_target_group" "main_target_group" {
  name     = "${var.app_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb" "main" {
  name               = "${var.app_name}-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = [aws_subnet.pub_subnet1.id, aws_subnet.pub_subnet2.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.app_name}-loadbalancer"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main_target_group.arn
  }
}
