variable "aws_region" {}
variable "nat_key_name" {}
variable "nat_gw_key" {}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnets_cidr" {
  default = ["10.0.2.0/24","10.0.3.0/24"]
}

variable "vpc_name_tag" {
  default = "Created By Terraform"
}

variable "vpc_env_tag" {
  default = null
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable nat_ami {
  type = "map"
  default = {
    eu-west-1 = "ami-0236d0cbbbe64730c"
    eu-west-2 = "ami-029dbaca987ff4afe"
    eu-west-3 = "ami-07f05abc8ce8470ee"
    eu-central-1 = "ami-0b86f70b539318af2" 
    eu-north-1 = "ami-bc4bc3c2"
  }
}



