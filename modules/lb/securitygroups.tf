resource "aws_security_group" "lbsg" {
  name = "LoadB_SecGr"

  # HTTP access to Load Balancer
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access to Load Balancer"
  }

  # outbound internet access
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.private_subnets_cidr}"
    description = "HTTP access from Load Balancer to Private Subnet"
  }

  vpc_id = "${var.vpc_id}"
}