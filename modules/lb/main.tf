resource "aws_lb_target_group" "lb_tg" {
  name         = "${var.lb_tg_name}"
  port         = 80
  protocol     = "HTTP"
  vpc_id       = "${var.vpc_id}"
  target_type  = "instance"
  slow_start   = 30  # Default is 0 min is 30
  deregistration_delay = 120 # default is 300
  
  health_check {
    interval = 30
    path     = "/users/sign_in"
    timeout  = 5
    matcher  = "200"
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb" "app_lb" {
  name                       = "${var.app_lb_name}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = ["${aws_security_group.lbsg.id}"]
  subnets                    = "${var.public_subnets_ids}"
  idle_timeout               = 60 # Default is 60
  enable_http2               = false # default is true
  ip_address_type            = "ipv4"
  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
  # access_logs {
  #   bucket  = "${aws_s3_bucket.lb_logs.bucket}"
  #   prefix  = "test-lb"
  #   enabled = true
  # }
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = "${aws_lb.app_lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.lb_tg.arn}"
  }
}

output "lb_address" {
  value = "${aws_lb.app_lb.dns_name}"
}

output "lb_tg_arn" {
  value = "${aws_lb_target_group.lb_tg.arn}"
}

output "lb_zone_id" {
  value = "${aws_lb.app_lb.zone_id}"
}