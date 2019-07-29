resource "aws_launch_configuration" "lnch_cfg" {
  name            = "${var.lnch_cfg_name}"
  image_id        = "${var.aws_ami_id}"
  instance_type   = "t2.micro"
  key_name        = "${var.lnch_cfg_key}"
  security_groups = "${var.security_gr_ids}"
  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app_asg" {
  name                 = "${var.asg_name}"
  launch_configuration = "${aws_launch_configuration.lnch_cfg.name}"
  min_size             = 1
  desired_capacity     = 1
  max_size             = 4
  vpc_zone_identifier  = "${var.private_subnet_ids}"
  target_group_arns    = "${var.lb_tg_arns}"
  tags = [
    # {
    #   key                 = "Role"
    #   value               = "myapp"
    #   propagate_at_launch = true
    # },
    {
      key                 = "Name"
      value               = "${var.asg_instnc_name}"
      propagate_at_launch = true
    },
  ]

  lifecycle {
    create_before_destroy = true
  }
}
