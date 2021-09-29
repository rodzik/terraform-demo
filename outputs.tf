output "ec2_public_ip" {
  value = module.demo-webserver.demo-instance.public_ip
}
