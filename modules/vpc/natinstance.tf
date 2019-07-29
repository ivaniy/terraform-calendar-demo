resource "aws_eip" "nat_public_ip" {
  vpc                       = true
  depends_on                = ["aws_internet_gateway.gw"]
}

resource "aws_instance" "nat_gateway" {
  ami                    = "${lookup(var.nat_ami,var.aws_region)}"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.public_subnet[0].id}"
  key_name               = "${var.nat_key_name}"
  vpc_security_group_ids = ["${aws_security_group.natsg.id}"]
  depends_on             = ["aws_eip.nat_public_ip"]
  source_dest_check      = false
  tags = {
    Name = "NAT_Gateway"
  }
  lifecycle {
    ignore_changes = [vpc_security_group_ids]
  }
}

resource "aws_eip_association" "eip_assoc_nat" {
  instance_id   = "${aws_instance.nat_gateway.id}"
  allocation_id = "${aws_eip.nat_public_ip.id}"
}

output "bastion_ip" {
  value = "${aws_eip.nat_public_ip.public_ip}"
}

output "bastion_user" {
  value = "ec2-user"
}

output "nat_gateway_interface_id" {
  value = "${aws_instance.nat_gateway.primary_network_interface_id}"
}