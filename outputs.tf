output "ec2_public_ip" {
  value = aws_instance.xops_web.public_ip
  description = "Public IP of the web server"
}
