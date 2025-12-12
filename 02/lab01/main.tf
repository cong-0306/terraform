#####################################################
# 1. provider 설정
# 2. VPC 생성
# 3. IGW 생성 및 연결
# 4. PubSN 생성
# 5. PubSN-RT 생성 및 연결
#####################################################

############################
# 1. provider 설정
############################
provider "aws" {
  region = "us-east-2"
}


############################
# 2. VPC 생성
############################
# VPC 생성 후 dns 호스트 이름 활성화
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc#enable_dns_hostnames-2
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"

  # argument_reference 에서 dns_hostname 서치
  # (Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults false.
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC" # 이름과 통일 시켜 주는 것이 좋다.
  }
}

############################
# 3. IGW 생성 및 연결
############################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}


############################
# 4. PubSN 생성
############################
# PubSN 생성
# * 공인 IP 활성화
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"

  # argument reference에서 map_public_ip_on_launch 서치
  # - (Optional) Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is false.
  map_public_ip_on_launch = true


  tags = {
    Name = "myPubSN"
  }

}

############################
# 5. PubSN-RT 생성 및 연결
############################
# PubSN-RT 생성
# * default route
# * default route
# * PubSN <- 연결 -> PubSN-RT
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRT"
  }
}

# 서브넷은 위에서 생성 됐고, 아래 코드로 라우팅 테이블과 연결함
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "myPubRTassoc" {
  subnet_id      = aws_subnet.myPubSN.id        # 서브넷 ID
  route_table_id = aws_route_table.myPubRT.id   # 라우팅 테이블 ID
}


