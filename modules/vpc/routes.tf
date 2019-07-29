resource "aws_route_table" "private_rt" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "Private_RT"
  }
}

resource "aws_default_route_table" "default_rt" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"
  tags = {
    Name = "Public_RT (Default)"
  }
}

resource "aws_route" "ExternalRoute" {
  route_table_id         = "${aws_vpc.main.main_route_table_id }"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_route" "Internal_RT" {
  route_table_id         = "${aws_route_table.private_rt.id }"
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = "${aws_instance.nat_gateway.id}"
  depends_on             = ["aws_instance.nat_gateway"]
}

resource "aws_route_table_association" "asso_subn_pr" {
  count          = "${length(aws_subnet.private_subnet)}"
  subnet_id      = "${aws_subnet.private_subnet[count.index].id}"
  route_table_id = "${aws_route_table.private_rt.id}"
}

resource "aws_route_table_association" "asso_subn_pub" {
  count          = "${length(aws_subnet.public_subnet)}"
  subnet_id      = "${aws_subnet.public_subnet[count.index].id}"
  route_table_id = "${aws_default_route_table.default_rt.id}"
}
