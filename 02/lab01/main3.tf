############
# NAT GW
# private subnet
# private route table + connect
# SG 생성
# EC2 생성
############

#################
# 1. NAT GW
# EIP 생성
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip#attribute-reference
# pubSN에 NAT GW 생성
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
#######################

resource "aws_eip" "myEIP" {
  domain   = "vpc"

  tags = {
    Name = "myEIP"
  }
}

resource "aws_nat_gateway" "myNAT-GW" {
  allocation_id = aws_eip.myEIP.id
  subnet_id     = aws_subnet.myPubSN.id

  tags = {
    Name = "myNAT-GW"
  }
  depends_on = [aws_internet_gateway.myIGW]
}

#################
# 2. Private SN
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
#################
resource "aws_subnet" "myPriSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "myPriSN"
  }
}

#################
# 3. PriSN-RT
# 생성
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# NAT GW = default route
# priSN <-> priSN-RT 연결
#http://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
#################
resource "aws_route_table" "myPriRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "10.0.2.0/24"
    gateway_id = aws_nat_gateway.myNAT-GW.id
  }

  tags = {
    Name = "myPriRT"
  }
}

resource "aws_route_table_association" "myPriRTAssoc" {
  subnet_id      = aws_subnet.myPriSN.id
  route_table_id = aws_route_table.myPriRT.id
}

#################
# 4. SG 생성
# 22/tcp, 80/tcp, 443/tcp ingress
# all egress
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

#################
resource "aws_security_group" "mySG2" {
  name        = "mySG2"
  description = "Allow TLS inbound ingress 22/tcp, 80/tcp, 443/tcp  outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG2"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mySG2_22" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "mySG2_80" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "mySG2_443" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "mySG2_all" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#################
# 5. EC2 생성
# PriSN에 생성
# user_data (Web server, SSH server)
# user_data 변경 시 재생성
# priSN에 생성
# mySG2 적용
##################

resource "aws_instance" "myEC2-2" {
  ami           = "ami-00e428798e77d38d9"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.mySG2.id]
  
  key_name = "mykeypair"
  user_data = <<-EOF
    #!/bin/bash
    dnf -y install httpd mod_ssl
    echo "MyWEB" > /var/www/html/index.html
    systemctl enable --now httpd 
    EOF

  subnet_id = aws_subnet.myPriSN.id
  tags = {
    Name = "myEC2-2"
  }
  
}