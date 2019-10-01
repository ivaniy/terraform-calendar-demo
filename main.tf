terraform {
  backend "s3" {
    bucket = "dolyuk-terraform-state"
    key    = "calendar/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  # access_key = "${var.aws_access_key}"
  # secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_key_pair" "nat_gw_key" {
  key_name   = "nat-gateway-key"
  public_key = "${file(var.nat_gw_pb_key)}"
}

resource "aws_key_pair" "calendar_key" {
  key_name   = "calendar-key"
  public_key = "${file(var.calendar_pb_key)}"
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = "${file(var.jenkins_pb_key)}"
}

module "dolyuk_vpc" {
  source = "./modules/vpc"
  aws_region = "${var.aws_region}"
  nat_gw_key = "~/.ssh/nat-gateway-key.pem"
  vpc_cidr = "172.31.0.0/21"
  public_subnets_cidr = "${var.public_subnets_cidr}"
  private_subnets_cidr = "${var.private_subnets_cidr}"
  vpc_name_tag = "Testing modules"
  vpc_env_tag = "dev"
  nat_key_name = "${aws_key_pair.nat_gw_key.key_name}"
}

module "db_instance" {
  source = "./modules/rds"
  identifier = "calendar"
  subnet_ids = "${module.dolyuk_vpc.private_subnets_ids}"
  vpc_id = "${module.dolyuk_vpc.vpc_id}"
  private_subnets_cidr = "${var.private_subnets_cidr}"
}

module "jenkins_instance" {
  source = "./modules/jenkins"
  ubuntu_ami = "${lookup(var.ubuntu_ami,var.aws_region)}"
  subnet_id = "${module.dolyuk_vpc.public_subnets_ids[0]}"
  jenkins_key_name = "${aws_key_pair.jenkins_key.key_name}"
  jenkins_key = "${var.jenkins_key}"
  public_subnets_cidr = "${var.public_subnets_cidr}"
  vpc_id = "${module.dolyuk_vpc.vpc_id}"
  nat_gateway_interface_id = "${module.dolyuk_vpc.nat_gateway_interface_id}"
  bastion_ip = "${module.dolyuk_vpc.bastion_ip}"
  bastion_user = "${module.dolyuk_vpc.bastion_user}"
  bastion_private_key = "${var.nat_gw_key}"

  aws_region = "${var.aws_region}"
  master_image_ami = "${aws_ami_from_instance.master_image.id}"
  calendar_key = "${var.calendar_key}"
  private_subnet_id = "${module.dolyuk_vpc.private_subnets_ids[0]}"

  db_host_name="${module.db_instance.db_address}"
  db_password="${module.db_instance.db_pass}"

  github_user="${var.github_user}"
  github_token="${var.github_token}"

  # db_host_name="aaa"
  # db_password="bbb"
}

module "sonarqube_instance" {
  source = "./modules/sonarqube"
  ubuntu_ami = "${lookup(var.ubuntu_ami,var.aws_region)}"
  subnet_id = "${module.dolyuk_vpc.public_subnets_ids[0]}"
  jenkins_key_name = "${aws_key_pair.jenkins_key.key_name}"
  jenkins_key = "${var.jenkins_key}"
  public_subnets_cidr = "${var.public_subnets_cidr}"
  vpc_id = "${module.dolyuk_vpc.vpc_id}"
  nat_gateway_interface_id = "${module.dolyuk_vpc.nat_gateway_interface_id}"
  bastion_ip = "${module.dolyuk_vpc.bastion_ip}"
  bastion_user = "${module.dolyuk_vpc.bastion_user}"
  bastion_private_key = "${var.nat_gw_key}"
  jenkins_address = "http://${module.jenkins_instance.jenkins_ip}:8080" 
}


resource "aws_instance" "master_image" {
  ami                    = "${lookup(var.ubuntu_ami,var.aws_region)}"
  instance_type          = "t2.micro"
  subnet_id              = "${module.dolyuk_vpc.private_subnets_ids[0]}"
  key_name               = "${aws_key_pair.calendar_key.key_name}"
  vpc_security_group_ids = ["${module.dolyuk_vpc.security_group_websg_id}"]
  associate_public_ip_address = false
  tags = {
    Name = "Master Image"
  }

  connection {
    type = "ssh"
    host = "${self.private_ip}"
    user        = "ubuntu"
    private_key = "${file(var.calendar_key)}"
    bastion_host = "${module.dolyuk_vpc.bastion_ip}"
    bastion_user = "${module.dolyuk_vpc.bastion_user}"
    bastion_private_key = "${file(var.nat_gw_key)}"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = ["echo 'Hello Master Image'"]
  }
}

resource "null_resource" "master_image_provisioner" {
  depends_on = ["aws_instance.master_image"]
  triggers = {
    cluster_instance_ids = "[${aws_instance.master_image.id}]"
  }
  connection {
    type = "ssh"
    host = "${aws_instance.master_image.private_ip}"
    user        = "ubuntu"
    private_key = "${file(var.calendar_key)}"
    bastion_host = "${module.dolyuk_vpc.bastion_ip}"
    bastion_user = "${module.dolyuk_vpc.bastion_user}"
    bastion_private_key = "${file(var.nat_gw_key)}"
  }

  provisioner "local-exec" {
    command = "ansible-playbook ./ansible/master_image.yml -i ec2.py --extra-vars \"ansible_user=ubuntu ansible_ssh_private_key_file=${var.calendar_key}\""
    environment = {
      ANSIBLE_CONFIG="./ansible/ansible.cfg"
      ANSIBLE_SSH_ARGS="-C -o ControlMaster=auto -o ControlPersist=300s -o ProxyCommand=\"ssh -i ${var.nat_gw_key} -o StrictHostKeyChecking=no -W %h:%p -q ${module.dolyuk_vpc.bastion_user}@${module.dolyuk_vpc.bastion_ip}\""
      ANSIBLE_FORCE_COLOR=true
    } 
  }

  provisioner "remote-exec" {
    # Test Waking instance before snapshot  
    inline = ["sleep 5s",
              "echo 'Waking'"]
  }  
}

resource "aws_ami_from_instance" "master_image" {
    name = "Master Image"
    source_instance_id = "${aws_instance.master_image.id}"
    snapshot_without_reboot = false
    depends_on = ["null_resource.master_image_provisioner"]
}

resource "aws_instance" "first_deploy" {
  ami                    = "${aws_ami_from_instance.master_image.id}"
  instance_type          = "t2.micro"
  subnet_id              = "${module.dolyuk_vpc.private_subnets_ids[0]}"
  key_name               = "${aws_key_pair.calendar_key.key_name}"
  vpc_security_group_ids = ["${module.dolyuk_vpc.security_group_websg_id}"]
  associate_public_ip_address = false
  tags = {
    Name = "First Deploy"
  }

  connection {
    type = "ssh"
    host = "${self.private_ip}"
    user        = "ubuntu"
    private_key = "${file(var.calendar_key)}"
    bastion_host = "${module.dolyuk_vpc.bastion_ip}"
    bastion_user = "${module.dolyuk_vpc.bastion_user}"
    bastion_private_key = "${file(var.nat_gw_key)}"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = ["echo 'Hello First Deploy'"]
  }
}

resource "null_resource" "first_deploy_provisioner" {
  depends_on = ["aws_instance.first_deploy"]
  triggers = {
    cluster_instance_ids = "[${aws_instance.first_deploy.id}]"
  }
  connection {
    type = "ssh"
    host = "${aws_instance.first_deploy.private_ip}"
    user        = "ubuntu"
    private_key = "${file(var.calendar_key)}"
    bastion_host = "${module.dolyuk_vpc.bastion_ip}"
    bastion_user = "${module.dolyuk_vpc.bastion_user}"
    bastion_private_key = "${file(var.nat_gw_key)}"
  }

  provisioner "local-exec" {
    command = "ansible-playbook ./ansible/calendar.yml -i ec2.py --extra-vars \"ansible_user=ubuntu ansible_ssh_private_key_file=${var.calendar_key} db_host_name=${module.db_instance.db_address} db_password=${module.db_instance.db_pass}\""
    environment = {
      ANSIBLE_CONFIG="./ansible/ansible.cfg"
      ANSIBLE_SSH_ARGS="-o ControlPersist=300s -o ProxyCommand=\"ssh -i ${var.nat_gw_key} -o StrictHostKeyChecking=no -W %h:%p -q ${module.dolyuk_vpc.bastion_user}@${module.dolyuk_vpc.bastion_ip}\""
      ANSIBLE_FORCE_COLOR=true
    } 
  }

  provisioner "remote-exec" {
    # Test Waking instance before snapshot  
    inline = ["sleep 5s",
              "echo 'Waking'"]
  }  
}

resource "aws_ami_from_instance" "base_image" {
    name = "Base Calendar Image"
    source_instance_id = "${aws_instance.first_deploy.id}"
    snapshot_without_reboot = false
    depends_on = ["null_resource.first_deploy_provisioner"]
}

module "app_loadbalancer" {
  source = "./modules/lb"
  lb_tg_name = "calendar-tg"
  vpc_id = "${module.dolyuk_vpc.vpc_id}"
  app_lb_name = "calendar-lb"
  private_subnets_cidr = "${var.private_subnets_cidr}"
  public_subnets_ids = "${module.dolyuk_vpc.public_subnets_ids}"
}

module "autoscaling" {
  source = "./modules/asg"
  lnch_cfg_name = "Calendar_instances"
  aws_ami_id = "${aws_ami_from_instance.base_image.id}"
  security_gr_ids = ["${module.dolyuk_vpc.security_group_websg_id}"]
  asg_name = "calendar-asg"
  private_subnet_ids = "${module.dolyuk_vpc.private_subnets_ids}"
  lb_tg_arns = ["${module.app_loadbalancer.lb_tg_arn}"]
  asg_instnc_name = "Calendar Instance"
  lnch_cfg_key = "calendar-key" #"${aws_key_pair.calendar_key.key_name}"  
}

module "route53_druk" {
  source = "./modules/route53_lb"
  domain_name = "3ddruk.com.ua"
  lb_address = "${module.app_loadbalancer.lb_address}"
  lb_zone_id = "${module.app_loadbalancer.lb_zone_id}"
}

output "jenkins_address" {
   value = "http://${module.jenkins_instance.jenkins_ip}:8080" 
}

output "jenkins_pass" {
   value = "${module.jenkins_instance.jenkins_password}" 
}

output "sonarqube_address" {
   value = "http://${module.sonarqube_instance.sonarqube_ip}:9000" 
}