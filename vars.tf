# variable "aws_access_key" {}
# variable "aws_secret_key" {}

variable "aws_region" {
  default = "eu-west-1"
}

variable "public_subnets_cidr" {
  default = ["172.31.0.0/24","172.31.1.0/24"]
}

variable "private_subnets_cidr" {
  default = ["172.31.3.0/24","172.31.4.0/24"]
}

variable ubuntu_ami {
  type = "map"
  default = {
    eu-west-1 = "ami-06358f49b5839867c"
    eu-west-2 = "ami-077a5b1762a2dde35"
    eu-west-3 = "ami-0ad37dbbe571ce2a1"
    eu-central-1 = "ami-0ac05733838eabc06" 
    eu-north-1 = "ami-ada823d3"
  }
}

variable "nat_gw_key" {
  default = "~/.ssh/nat-gateway-key.pem"
}

variable "jenkins_key" {
  default = "~/.ssh/jenkins-key.pem"
}

variable "calendar_key" {
  default = "~/.ssh/calendar-key.pem"
}

variable "nat_gw_pb_key" {
  default = "~/.ssh/nat-gateway-key.pub"
}

variable "jenkins_pb_key" {
  default = "~/.ssh/jenkins-key.pub"
}

variable "calendar_pb_key" {
  default = "~/.ssh/calendar-key.pub"
}

# variable "vpc_cidr" {
#   default = "192.168.0.0/22"
# }

# variable "public_subnets_cidr" {
#   default = ["192.168.0.0/24", "192.168.1.0/24"]
# }

# variable "private_subnets_cidr" {
#   default = ["192.168.2.0/24","192.168.3.0/24"]
# }

# variable "aws_region" {
#   default = "eu-west-1"
# }

# variable "ec2_ami_eu_central_1" {
#   description = "Image for all instance"
#   default     = "ami-09def150731bdbcc2"
# }

# variable "ec2_ami_eu_west_1" {
#   description = "Image for all instance"
#   default     = "ami-0bbc25e23a7640b9b"
# }

# variable "nat_ami_eu_west_1" {
#   description = "NAT Instance Image"
#   default     = "ami-0236d0cbbbe64730c"
# }

# variable "ubuntu_ami_eu_west_1" {
#   description = "Ubuntu Instance Image"
#   default     = "ami-01e6a0b85de033c99"
# }

# variable "myprivate_key" {
#   default = "../.ssh/id_rsa"
# }

# variable "nat_gw_key" {
#   default = "../.ssh/nat-gateway-key.pem"
# }

# variable "jenkins_key" {
#   default = "../.ssh/jenkins-key.pem"
# }

# variable "calendar_key" {
#   default = "../.ssh/calendar-key.pem"
# }

# variable "roure53_Domain" {
#   default = "3ddruk.com.ua"
# }
