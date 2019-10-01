resource "aws_security_group" "sonarqube_sg" {
  name = "sonarqube_SecGr"

  # Global Web access to Sonarqube 
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Global access to sonarqube"
  }


  # SSH access to sonarqube from Public Subnet
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.public_subnets_cidr}"
    description = "SSH access to sonarqube from Public Subnet"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "outbound internet access"
  }

  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group" "sonarqube_nat_sg" {
  name = "sonarqube_nat_SecGr"

  # Allow ssh to sonarqube via SSH
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.sonarqube.private_ip}/32"]
    description = "Allow ssh to sonarqube via SSH"
  }

  vpc_id = "${var.vpc_id}"
}

resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = "${aws_security_group.sonarqube_nat_sg.id}"
  network_interface_id = "${var.nat_gateway_interface_id}"
}