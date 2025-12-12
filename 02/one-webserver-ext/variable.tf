# [입력 변수]
variable "security_group_name" {
  description ="The name of the security group"
  type = string
  default = "allow_8080"
}

variable "server_port" {
    description = "My EC2 Server Port"
    type = number
    default = 8080
}