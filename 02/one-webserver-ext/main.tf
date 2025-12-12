provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "allow_8080" {
  # name        = "allow_8080"
  name = var.security_group_name
  description = "Allow TLS inbound traffic and all outbound traffic"

  tags = {
    Name = "allow_8080"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_8080_http" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  #from_port         = 8080
  #to_port           = 8080
  from_port         = var.server_port
  to_port           = var.server_port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "myinstance" {
  ami                    = "ami-0f5fcdfbd140e4ab7"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_8080.id]

  user_data_replace_on_change = true
  user_data                   = <<-EOF
        #!/bin/bash
        echo "Hello World" > index.html
        nohup busybox httpd -f -p 8080 &
        EOF

  tags = {
    Name = "My-First-Instance"
  }
}

