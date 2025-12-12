##########################
# 1. SG 생성
# 2. EC2 생성
##########################

################
# 1. SG 생성
# ingress : 80/tcp 443/tcp
# engress : all
################
resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow TLS inbound 80/tcp, 443/tcp and outbound all"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}
resource "aws_vpc_security_group_ingress_rule" "mySG_22" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "mySG_80" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "mySG_443" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "mySG_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}



################
# 2. EC2 생성
# user_data (80/tcp, 443/tcp)
# user_data 변경 시 EC2 재생성
# subnet에 EC2 위치시키기
# mySG 적용
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#argument-reference
################
# Key pair 생성 및 설정 - mykeypair
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
##################
#ssh-keygen -t rsa -N "" -f ~/.ssh/mykeypair

resource "aws_key_pair" "deployer" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/mykeypair.pub")
}
resource "aws_instance" "myEC2" {
  ami           = "ami-00e428798e77d38d9"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.mySG.id]
  user_data_replace_on_change = true
  key_name = "mykeypair"
  user_data = <<-EOF
    #!/bin/bash
    dnf -y install httpd mod_ssl
    echo "MyWEB" > /var/www/html/index.html
    systemctl enable --now httpd 
    EOF
  subnet_id = aws_subnet.myPubSN.id
  tags = {
    Name = "myEC2"
  }
}
