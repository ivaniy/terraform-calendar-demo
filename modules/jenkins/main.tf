resource "random_string" "jenkins_pass" {
  length = 12
  special = false
}

resource "aws_instance" "jenkins" {
  ami                    = "${var.ubuntu_ami}"
  instance_type          = "t2.micro"
  subnet_id              = "${var.subnet_id}"
  key_name               = "${var.jenkins_key_name}"
  vpc_security_group_ids = ["${aws_security_group.jenkins_sg.id}"]
  associate_public_ip_address = true
  tags = {
    Name = "Jenkins"
  }

  connection {
    type = "ssh"
    host = "${self.public_ip}"
    user        = "ubuntu"
    private_key = "${file(var.jenkins_key)}"
    bastion_host = "${var.bastion_ip}"
    bastion_user = "${var.bastion_user}"
    bastion_private_key = "${file(var.bastion_private_key)}"
  }
}

# SSH access from NAT server to Jenkins

resource "null_resource" "Jenkins-Provisioner" {
  depends_on = ["aws_network_interface_sg_attachment.sg_attachment"]
  connection {
    type = "ssh"
    host = "${aws_instance.jenkins.private_ip}"
    user        = "ubuntu"
    private_key = "${file(var.jenkins_key)}"
    bastion_host = "${var.bastion_ip}"
    bastion_user = "${var.bastion_user}"
    bastion_private_key = "${file(var.bastion_private_key)}"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = ["echo 'Hello World'"]
  }

  provisioner "local-exec" {
    command = "ansible tag_Name_Jenkins -m apt -a \"update_cache=yes force_apt_get=yes\"  -i ~/terraform/ec2.py --become --extra-vars \"ansible_user=ubuntu ansible_ssh_private_key_file=${var.jenkins_key} ansible_ssh_common_args='-o ProxyCommand=\\\"ssh -i ${var.bastion_private_key} -o StrictHostKeyChecking=no -W %h:%p -q ${var.bastion_user}@${var.bastion_ip}\\\"'\""
    environment = {
      ANSIBLE_CONFIG="${path.module}/ansible.cfg"
    } 
  }

  provisioner "local-exec" {
    command = "ansible-galaxy install geerlingguy.jenkins"
    environment = {
      ANSIBLE_CONFIG="${path.module}/ansible.cfg"
    } 
  }

  provisioner "local-exec" {
    command = "ansible-playbook ${path.module}/jenkins.yml -i ~/terraform/ec2.py --extra-vars \"ansible_user=ubuntu ansible_ssh_private_key_file=${var.jenkins_key} jenkins_admin_username=jenkinsadmin jenkins_admin_password=${random_string.jenkins_pass.result} jenkins_hostname=${aws_instance.jenkins.public_ip} ansible_ssh_common_args='-o ProxyCommand=\\\"ssh -i ${var.bastion_private_key} -o StrictHostKeyChecking=no -W %h:%p -q ${var.bastion_user}@${var.bastion_ip}\\\"'\""
    environment = {
      ANSIBLE_CONFIG="${path.module}/ansible.cfg"
    } 
  }
}

output "jenkins_ip" {
   value = "${aws_instance.jenkins.public_ip}" 
}

output "jenkins_password" {
   value = "${random_string.jenkins_pass.result}" 
}

