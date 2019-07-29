resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags = { 
    Name = "${var.vpc_name_tag}"
    Env = "${var.vpc_env_tag}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_subnet" "public_subnet" {
  count                   = "${length(var.public_subnets_cidr)}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.public_subnets_cidr[count.index]}"
  map_public_ip_on_launch = false
  depends_on              = ["aws_internet_gateway.gw"]
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  tags = {
    Name = "Subnet_Pub${count.index+1}"
    Type = "Public"
  }
}

resource "aws_subnet" "private_subnet" {
  count                   = "${length(var.private_subnets_cidr)}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.private_subnets_cidr[count.index]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  tags = {
    Name = "Subnet_Priv${count.index+1}"
    Type = "Private"
  }
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "private_subnets_ids" {
  value = "${aws_subnet.private_subnet[*].id}"
}

output "public_subnets_ids" {
  value = "${aws_subnet.public_subnet[*].id}"
}