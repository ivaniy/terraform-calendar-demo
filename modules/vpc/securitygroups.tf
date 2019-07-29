resource "aws_security_group" "natsg" {
  name = "Nat_SecGr"
  # Inbound Rules
  # HTTP access from Private network to NAT
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.private_subnets_cidr}"
    description = "HTTP access from Private network to NAT"
  }

  # HTTPS access from Private network to NAT
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.private_subnets_cidr}"
    description = "HTTPS access from Private network to NAT"
  }
  
  # PING/ICMP access from Private network to NAT
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = "${var.private_subnets_cidr}"
    description = "_"
  }

  # SSH access to NAT server
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "PING/ICMP access from Private network to NAT"
  }

  # Outbound Rules
  # HTTP access from NAT to anywhere
  egress {
    to_port     = 80
    from_port   = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access from NAT to anywhere"
  }

  # HTTPS access from NAT to anywhere
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access from NAT to anywhere"
  }
  
  # SSH access from NAT server to private network
  egress {
    to_port     = 22
    from_port   = 22
    protocol    = "tcp"
    cidr_blocks = "${var.private_subnets_cidr}"
    description = "SSH access from NAT server to private network"
  }


  # PING/ICMP access from NAT to anywhere
  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "PING/ICMP access from NAT to anywhere"
  }

  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_security_group" "websg" {
  name = "Web_SecGr"

  # SSH access from Public Subnet
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.public_subnets_cidr}"
    description = "SSH access from Public Subnet"
  }

  # HTTP access from Public Subnet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.public_subnets_cidr}"
    description = "HTTP access from Public Subnet"
  }

  # PING/ICMP access from Public Subnet
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = "${var.private_subnets_cidr}"
    description = "PING/ICMP access from Public Subnet"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "outbound internet access"
  }

  vpc_id = "${aws_vpc.main.id}"
}

output "security_group_websg_id" {
  value = "${aws_security_group.websg.id}"
}