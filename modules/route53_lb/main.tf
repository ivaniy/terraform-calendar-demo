data "aws_route53_zone" "domain" {
  name         = "${var.domain_name}"
  private_zone = false
}

resource "aws_route53_record" "domain_rec" {
  zone_id = "${data.aws_route53_zone.domain.zone_id}"
  name    = "${var.domain_name}"
  type    = "A"
  alias {
    name                   = "${var.lb_address}"
    zone_id                = "${var.lb_zone_id}"
    evaluate_target_health = true
  }
}
