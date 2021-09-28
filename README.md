# Installation

1. `brew install terraform`
2. `terraform init`
3. Make sure AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environments are set up.
4. `cp terraform.tfvars.example terraform.tfvars` and adjust my_ip
5. `terraform apply`
6. `terraform destroy` if you need to get rid of the infra
