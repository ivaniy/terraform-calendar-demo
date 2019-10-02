resource "aws_instance" "first_deploy" {
  ami                    = "${var.master_ami}"
  instance_type          = "t2.micro"
  subnet_id              = "${var.private_subnet_ids[0]}"
  key_name               = "${var.calendar_key_name}"
  vpc_security_group_ids = "${var.security_groups}"
  associate_public_ip_address = false
  tags = {
    Name = "First Deploy"
  }

  connection {
    type = "ssh"
    host = "${self.private_ip}"
    user        = "ubuntu"
    private_key = "${file(var.calendar_key)}"
    bastion_host = "${var.bastion_ip}"
    bastion_user = "${var.bastion_user}"
    bastion_private_key = "${file(var.bastion_private_key)}"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = ["echo 'Hello First Deploy Instance for base image'"]
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
    bastion_host = "${var.bastion_ip}"
    bastion_user = "${var.bastion_user}"
    bastion_private_key = "${file(var.bastion_private_key)}"
  }

  provisioner "local-exec" {
    command = "ansible-playbook ./ansible/calendar.yml -i ec2.py --extra-vars \"ansible_user=ubuntu ansible_ssh_private_key_file=${var.calendar_key} db_host_name=${var.db_host_name} db_password=${var.db_password}\""
    environment = {
      ANSIBLE_CONFIG="./ansible/ansible.cfg"
      ANSIBLE_SSH_ARGS="-o ControlPersist=300s -o ProxyCommand=\"ssh -i ${var.bastion_private_key} -o StrictHostKeyChecking=no -W %h:%p -q ${var.bastion_user}@${var.bastion_ip}\""
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

output "base_ami" {
   value = "${aws_ami_from_instance.base_image.id}" 
}
