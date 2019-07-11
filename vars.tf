variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "aws_region" {
  default = "eu-west-1"
}

variable "ec2_ami_eu_central_1" {
  description = "Image for all instance"
  default     = "ami-09def150731bdbcc2"
}

variable "ec2_ami_eu_west_1" {
  description = "Image for all instance"
  default     = "ami-0bbc25e23a7640b9b"
}

variable "nat_ami_eu_west_1" {
  description = "NAT Instance Image"
  default     = "ami-0236d0cbbbe64730c"
}

variable "ubuntu_ami_eu_west_1" {
  description = "Ubuntu Instance Image"
  default     = "ami-01e6a0b85de033c99"
}

variable "myprivate_key" {
  default = "../.ssh/id_rsa"
}

variable "nat_gw_key" {
  default = "../.ssh/nat-gateway-key.pem"
}

variable "calendar_key" {
  default = "../.ssh/calendar-key.pem"
}

variable "mypublic_key" {
  default = "../.ssh/id_rsa.pub"
}
