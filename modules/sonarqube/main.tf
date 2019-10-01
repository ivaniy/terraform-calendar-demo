resource "aws_instance" "sonarqube" {
  ami                    = "${var.ubuntu_ami}"
  instance_type          = "t2.small"
  subnet_id              = "${var.subnet_id}"
  key_name               = "${var.jenkins_key_name}"
  vpc_security_group_ids = ["${aws_security_group.sonarqube_sg.id}"]
  associate_public_ip_address = true
  tags = {
    Name = "Sonarqube"
  }

  connection {
    type = "ssh"
    host = "${self.private_ip}"
    user        = "ubuntu"
    private_key = "${file(var.jenkins_key)}"
    bastion_host = "${var.bastion_ip}"
    bastion_user = "${var.bastion_user}"
    bastion_private_key = "${file(var.bastion_private_key)}"
  }
}

resource "null_resource" "Sonarqube-Provisioner" {
  depends_on = ["aws_network_interface_sg_attachment.sg_attachment"]
  connection {
    type = "ssh"
    host = "${aws_instance.sonarqube.private_ip}"
    user        = "ubuntu"
    private_key = "${file(var.jenkins_key)}"
    bastion_host = "${var.bastion_ip}"
    bastion_user = "${var.bastion_user}"
    bastion_private_key = "${file(var.bastion_private_key)}"
  }

  provisioner "remote-exec" {
    inline = ["echo 'Hello Sonarqube Instance'"]
  }

  provisioner "local-exec" {
    command = "ansible-playbook ${path.module}/sonarqube.yml -i ~/terraform/ec2.py --limit tag_Name_Sonarqube --extra-vars \"ansible_user=ubuntu ansible_ssh_private_key_file=${var.jenkins_key} jenkins_address=${var.jenkins_address}\""
    environment = {
      ANSIBLE_CONFIG="${path.module}/ansible.cfg"
      ANSIBLE_SSH_ARGS="-o ProxyCommand=\"ssh -i ${var.bastion_private_key} -o StrictHostKeyChecking=no -W %h:%p -q ${var.bastion_user}@${var.bastion_ip}\""
      ANSIBLE_FORCE_COLOR=true
    } 
  }
}

output "sonarqube_ip" {
   value = "${aws_instance.sonarqube.public_ip}" 
}

