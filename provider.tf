provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_vpc" "dolyuk_vpc" {
  cidr_block           = "192.168.0.0/22"
  enable_dns_hostnames = true

  tags = {
    Name = "dolyuk_vpc"
    Env = "test"
  }
}
   
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.dolyuk_vpc.id}"
}

resource "aws_subnet" "subnet1_public" {
  vpc_id                  = "${aws_vpc.dolyuk_vpc.id}"
  cidr_block              = "192.168.0.0/24"
  map_public_ip_on_launch = false
  depends_on              = ["aws_internet_gateway.gw"]

  tags = {
    Name = "Subnet1_Pub"
    Type = "Public"
  }
}

resource "aws_subnet" "subnet2_public" {
  vpc_id                  = "${aws_vpc.dolyuk_vpc.id}"
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = false
  depends_on              = ["aws_internet_gateway.gw"]

  tags = {
    Name = "Subnet2_Pub"
    Type = "Public"
  }
}

resource "aws_subnet" "subnet1_private" {
  vpc_id                  = "${aws_vpc.dolyuk_vpc.id}"
  cidr_block              = "192.168.2.0/24"
  map_public_ip_on_launch = false
  depends_on              = ["aws_internet_gateway.gw"]

  tags = {
    Name = "Subnet1_Priv"
    Type = "Private"
  }
}

resource "aws_subnet" "subnet2_private" {
  vpc_id                  = "${aws_vpc.dolyuk_vpc.id}"
  cidr_block              = "192.168.3.0/24"
  map_public_ip_on_launch = false
  depends_on              = ["aws_internet_gateway.gw"]

  tags = {
    Name = "Subnet2_Priv"
    Type = "Private"
  }
}


resource "aws_security_group" "natsg" {
  name = "Nat_SecGr"
  # Inbound Rules
  # HTTP access from Private network to NAT
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["192.168.2.0/23"]
  }

  # HTTPS access from Private network to NAT
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["192.168.2.0/23"]
  }
  
  # PING/ICMP access from Private network to NAT
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["192.168.2.0/23"]
  }

  # SSH access to NAT server
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules
  # HTTP access from NAT to anywhere
  egress {
    to_port     = 80
    from_port   = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from NAT to anywhere
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # SSH access from NAT server to private network
  egress {
    to_port     = 22
    from_port   = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.2.0/23"]
  }

  # PING/ICMP access from NAT to anywhere
  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.dolyuk_vpc.id}"
}

resource "aws_security_group" "websg" {
  name = "Web_SecGr"

  # SSH access from Public Subnet
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/23"]
  }

  # PING/ICMP access from Public Subnet
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["192.168.2.0/23"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.dolyuk_vpc.id}"
}

resource "aws_route_table" "private_rt" {
  vpc_id = "${aws_vpc.dolyuk_vpc.id}"
  tags = {
    Name = "Private_RT"
  }
}

resource "aws_default_route_table" "def_rt" {
  default_route_table_id = "${aws_vpc.dolyuk_vpc.default_route_table_id}"

  tags = {
    Name = "Public_RT (Default)"
  }
}

resource "aws_route" "ExternalRoute" {
  route_table_id         = "${aws_vpc.dolyuk_vpc.main_route_table_id }"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}


resource "aws_route_table_association" "asso_subn1_pr" {
  subnet_id      = "${aws_subnet.subnet1_private.id}"
  route_table_id = "${aws_route_table.private_rt.id}"
}

resource "aws_route_table_association" "asso_subn2_pr" {
  subnet_id      = "${aws_subnet.subnet2_private.id}"
  route_table_id = "${aws_route_table.private_rt.id}"
}

resource "aws_route_table_association" "asso_subn1_pub" {
  subnet_id      = "${aws_subnet.subnet1_public.id}"
  route_table_id = "${aws_default_route_table.def_rt.id}"
}

resource "aws_route_table_association" "asso_subn2_pub" {
  subnet_id      = "${aws_subnet.subnet2_public.id}"
  route_table_id = "${aws_default_route_table.def_rt.id}"
}

resource "aws_eip" "nat_public_ip" {
  vpc                       = true
  # instance                  = "${aws_instance.nat_gateway.id}"
  # associate_with_private_ip = "${aws_instance.nat_gateway.private_ip}"
  depends_on                = ["aws_internet_gateway.gw"]
}

resource "aws_eip_association" "eip_assoc_nat" {
  instance_id   = "${aws_instance.nat_gateway.id}"
  allocation_id = "${aws_eip.nat_public_ip.id}"
}

resource "aws_instance" "nat_gateway" {
  ami                    = "${var.nat_ami_eu_west_1}"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.subnet1_public.id}"
  key_name               = "nat-gateway-key"
  vpc_security_group_ids = ["${aws_security_group.natsg.id}"]
  depends_on             = ["aws_eip.nat_public_ip"]
  source_dest_check      = false
  tags = {
    Name = "NAT_Gateway"
  }

  connection {
    type = "ssh"
    host = "${aws_eip.nat_public_ip.public_ip}"
    user        = "ec2-user"
    private_key = "${file(var.nat_gw_key)}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "calendar_lnch_cfg" {
  name            = "Calendar_instances"
  image_id        = "${var.ubuntu_ami_eu_west_1}"
  instance_type   = "t2.micro"
  key_name        = "calendar-key"
  security_groups = ["${aws_security_group.websg.id}"]
  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bar" {
  name                 = "asg-calendar"
  launch_configuration = "${aws_launch_configuration.calendar_lnch_cfg.name}"
  min_size             = 1
  desired_capacity     = 1
  max_size             = 4
  vpc_zone_identifier  = ["${aws_subnet.subnet1_private.id}", "${aws_subnet.subnet2_private.id}"]
  tags = [
    {
      key                 = "Role"
      value               = "calendar"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "Calendar Instance"
      propagate_at_launch = true
    },
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_route" "Int_RT" {
#   route_table_id         = "${aws_vpc.terraform_vpc.main_route_table_id}"
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = "${aws_internet_gateway.gw.id}"
# }

# resource "aws_key_pair" "terraform_key" {
#   key_name   = "terraform_key"
#   public_key = "${file(var.mypublic_key)}"
# }

# resource "aws_instance" "ansible" {
#   ami                    = "${var.ec2_ami_eu_west_1}"
#   instance_type          = "t2.micro"
#   subnet_id              = "${aws_subnet.terraform_subnet.id}"
#   key_name               = "terraform_key"
#   vpc_security_group_ids = ["${aws_security_group.terraform_sg.id}"]

#   tags = {
#     Name = "ansible"
#   }

#   connection {
#     type = "ssh"
#     host = self.public_ip
#     user        = "ec2-user"
#     private_key = "${file(var.myprivate_key)}"
#   }

#   provisioner "remote-exec" {
#     inline = ["sudo yum update -y && sudo amazon-linux-extras install epel -y && sudo yum install git ansible -y ",
#       "git clone https://github.com/ivaniy/ansible-elk.git",
#     ]
#   }

#   provisioner "file" {
#     content     = "${file(var.myprivate_key)}"
#     destination = "/home/ec2-user/.ssh/id_rsa"
#   }

#   provisioner "remote-exec" {
#     inline = ["sudo chmod 400 /home/ec2-user/.ssh/id_rsa"]
#   }
# }

# resource "aws_instance" "elk" {
#   ami                    = "${var.ec2_ami_eu_west_1}"
#   instance_type          = "t2.micro"
#   subnet_id              = "${aws_subnet.terraform_subnet.id}"
#   key_name               = "terraform_key"
#   vpc_security_group_ids = ["${aws_security_group.terraform_sg.id}"]

#   tags = {
#     Name = "elk"
#   }

#   connection {
#     type = "ssh"
#     host = self.public_ip
#     user        = "ec2-user"
#     private_key = "${file(var.myprivate_key)}"
#   }

#   provisioner "remote-exec" {
#     inline = ["sudo yum update -y "]

#     #&& sudo amazon-linux-extras install epel -y && sudo yum install git ansible -y ",
#     #  "git clone https://github.com/ivaniy/ansible-elk.git",
#   }

#   #  provisioner "file" {
#   #    content     = "${file(../.ssh/id_rsa)}"
#   #    destination = "/home/ec2-user/.ssh/id_rsa"
#   #  }
# }

# resource "aws_eip" "elk_public_ip" {
#   vpc                       = true
#   instance                  = "${aws_instance.elk.id}"
#   associate_with_private_ip = "${aws_instance.elk.private_ip}"
#   depends_on                = ["aws_internet_gateway.gw"]
# }

# output "aws_instance_elk_public_ip" {
#   value = "${aws_eip.elk_public_ip.public_ip}"
# }

# output "aws_instance_ansible_public_ip" {
#   value = "${aws_instance.ansible.public_ip}"
# }

# resource "null_resource" "cluster" {
#   # Changes to any instance of the cluster requires re-provisioning

#   # Bootstrap script can run on any instance of the cluster
#   # So we just choose the first in this case
#   connection {
#     host        = "${aws_instance.ansible.public_ip}"
#     user        = "ec2-user"
#     private_key = "${file(var.myprivate_key)}"
#   }

#   provisioner "remote-exec" {
#     # Bootstrap script called with private_ip of each node in the clutser
#     inline = ["cd ansible-elk",
#       "sed -i 's/host_ip/${aws_eip.elk_public_ip.public_ip}/g' hosts",
#       "ansible-playbook elk.yml",
#     ]
#   }
# }
