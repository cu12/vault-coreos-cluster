/********************
  Internal DNS Zone
********************/
resource "aws_route53_zone" "private" {
  name    = "${var.domain}"
  comment = "${var.aws_account} private zone (Managed by Terraform)"
  vpc_id  = "${aws_vpc.vpc.id}"

  # Tags
  tags {
    Environment = "${var.prefix}"
  }
}

/********
  Vault
********/
# Instances
resource "aws_route53_record" "vault" {
  count   = "${var.vault["size"]}"
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "${var.prefix}-vault${format("%02d", count.index + 1)}.${var.domain}"
  type    = "A"
  ttl     = "300"
  records = ["${element(aws_instance.vault.*.private_ip, count.index)}"]
}

# LoadBalancer
resource "aws_route53_record" "vault-loadbalancer" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "${var.prefix}-vault.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_elb.vault.dns_name}"]
}
