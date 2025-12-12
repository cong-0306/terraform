# [출력 변수]
output "public_ip" {
  description = "My EC2 Public IP"
  value = aws_instance.myinstance.public_ip
}

output "public_dns_name" {
    description = "My EC2 DNS name"
    value =  aws_instance.myinstance.public_dns
}