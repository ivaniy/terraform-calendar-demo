resource "aws_security_group" "dbsg" {
  name = "DB_SecGr"

  # MySQL access from Private Subnet
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = "${var.private_subnets_cidr}"
    description = "MySQL access from Private Subnet"
  }

  # Outbound access to Private Subnet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "${var.private_subnets_cidr}"
    description = "Outbound access to Private Subnet"
  }

  vpc_id = "${var.vpc_id}"
}