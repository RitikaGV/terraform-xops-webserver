provider "aws" {
  region = "us-east-1"  # Change if needed
}

# VPC
resource "aws_vpc" "xops_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Subnet
resource "aws_subnet" "xops_subnet" {
  vpc_id                  = aws_vpc.xops_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "xops_igw" {
  vpc_id = aws_vpc.xops_vpc.id
}

# Route Table
resource "aws_route_table" "xops_rt" {
  vpc_id = aws_vpc.xops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.xops_igw.id
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "xops_rta" {
  subnet_id      = aws_subnet.xops_subnet.id
  route_table_id = aws_route_table.xops_rt.id
}

# Security Group
resource "aws_security_group" "xops_sg" {
  name        = "xops_sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.xops_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "xops_web" {
  ami                    = "ami-0c2b8ca1dad447f8a"  # Amazon Linux 2, us-east-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.xops_subnet.id
  vpc_security_group_ids = [aws_security_group.xops_sg.id]

  associate_public_ip_address = true
  key_name = "terraform-xops-key" # Replace with your AWS key pair name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              echo "<h1>Hello from XOps Web Server</h1>" > /var/www/html/index.html
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = {
    Name = "XOpsWebServer"
  }
}
