# Installation

1. `brew install terraform`
2. `terraform init`
3. Make sure AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environments are set up.
4. `cp terraform.tfvars.example terraform.tfvars` and adjust my_ip
5. `terraform apply`
6. `terraform destroy` if you need to get rid of the infra


# Infrastructure
This config creates following resources:
- postgres RDS
- ECS with EC2 instance
- ECR
- ssh key pair for ec2 access (uses ~/.ssh/id_rsa.pub)
- load balancer (redirects traffic to port 3000 of running container)
