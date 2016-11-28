/*****************
  Vault Template
*****************/
data "template_file" "bootstrap" {
  count = "${var.vault["size"]}"

  template = "-retry-join=${var.prefix}-vault${format("%02d", count.index + 1)}.${var.domain}"

  # Template Variables
  vars {
    prefix = "${var.prefix}"
    domain = "${var.domain}"
  }
}

data "template_file" "vault" {
  count = "${var.vault["size"]}"

  template = "${file("${path.root}/cloud-config/vault.tpl")}"

  # Template Variables
  vars {
    fqdn = "${var.prefix}-vault${format("%02d", count.index + 1)}.${var.domain}"

    # Consul Configuration
    consul_version   = "${var.consul_version}"
    bootstrap        = "${join(" ", data.template_file.bootstrap.*.rendered)}"
    bootstrap_expect = "${var.vault["size"]}"

    # Vault Configuration
    vault_version     = "${var.vault["version"]}"
    vault_config      = "${base64encode(file("${path.root}/vault-config/vault.hcl"))}"
    vault_address = "${var.vault_address}"
  }
}

/********
  Vault
********/
resource "aws_instance" "vault" {
  count = "${var.vault["size"]}"

  # General Config
  instance_type = "${var.vault["instance_type"]}"
  ami           = "${data.aws_ami.coreos.id}"
  user_data     = "${element(data.template_file.vault.*.rendered, count.index)}"
  key_name      = "${aws_key_pair.default.key_name}"

  # Networking
  subnet_id              = "${element(aws_subnet.private.*.id, count.index % length(compact(var.availability_zones)))}"
  vpc_security_group_ids = ["${aws_security_group.vault.id}"]

  # Storage
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  # Tags
  tags {
    Application = "Vault"
    Environment = "${var.prefix}"
    Name        = "${var.prefix}-${format("vault%02d", count.index + 1)}"
    Network     = "private"
  }
}

/*********************
  Vault LoadBalancer
*********************/
# Certificate
resource "aws_iam_server_certificate" "vault" {
  name_prefix      = "${var.prefix}-vault"
  certificate_body = "${file("${path.root}/certs/self-signed.pem")}"
  private_key      = "${file("${path.root}/certs/key.pem")}"

  lifecycle {
    create_before_destroy = true
  }
}

# LoadBalancer
resource "aws_elb" "vault" {
  name = "${var.prefix}-vault"

  # General Config
  instances = ["${aws_instance.vault.*.id}"]

  # Networking
  security_groups     = ["${aws_security_group.vault_loadbalancer.id}"]
  subnets             = ["${aws_subnet.public.*.id}"]
  connection_draining = false

  # Inbound Connections
  listener {
    instance_port      = 8200
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${aws_iam_server_certificate.vault.arn}"
  }

  # Healthcheck Config
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 3
    target              = "HTTP:8200/v1/sys/health"
    interval            = 5
  }

  # Tags
  tags {
    Application = "Vault"
    Environment = "${var.prefix}"
    Name        = "${var.prefix}-vault"
    Network     = "public"
  }
}
