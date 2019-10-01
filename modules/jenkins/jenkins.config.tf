resource "null_resource" "Jenkins-Configuration" {
  # triggers = {
  #   cluster_instance_ids = "${data.template_file.github_cred.rendered}, ${data.template_file.github_key.rendered}, ${data.template_file.mbpl_01_job.rendered}, ${data.template_file.mbpl_02_job.rendered}, ${data.template_file.aws_cloud_config.rendered}, ${path.module}/locale.groovy, ${path.module}/gitHubServerConfig.groovy"
  # }
  depends_on = ["null_resource.Jenkins-Provisioner"]

  connection {
    type = "ssh"
    host = "${aws_instance.jenkins.private_ip}"
    user        = "ubuntu"
    private_key = "${file(var.jenkins_key)}"
    bastion_host = "${var.bastion_ip}"
    bastion_user = "${var.bastion_user}"
    bastion_private_key = "${file(var.bastion_private_key)}"
  }

  # provisioner "file" {
  #   content     = "${data.template_file.mbpl_01_job.rendered}"
  #   destination = "/tmp/02-mbpl_01.job.groovy"
  # }
  
  provisioner "local-exec" {
    command = "ansible-playbook ${path.module}/jenkins_config.yml -i ~/terraform/ec2.py --limit tag_Name_Jenkins --extra-vars \"ansible_user=ubuntu ansible_ssh_private_key_file=${var.jenkins_key} jenkins_admin_username=jenkinsadmin jenkins_admin_password=${random_string.jenkins_pass.result} database_password=${var.db_password}  calendar_key_file=${var.calendar_key} db_host_name=${var.db_host_name} master_image_ami=${var.master_image_ami} aws_region=${var.aws_region} private_subnet_id=${var.private_subnet_id} github_user=${var.github_user} github_token=${var.github_token} \""
    environment = {
      ANSIBLE_CONFIG="${path.module}/ansible.cfg"
      ANSIBLE_SSH_ARGS="-o ProxyCommand=\"ssh -i ${var.bastion_private_key} -o StrictHostKeyChecking=no -W %h:%p -q ${var.bastion_user}@${var.bastion_ip}\""
      ANSIBLE_FORCE_COLOR=true
    } 
  }
}