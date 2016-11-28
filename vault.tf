/********************************
  Vault Instance Security Group
********************************/

resource "aws_security_group" "vault_instance" {
  name        = "${var.prefix}-vault_instance"
  description = "Vault instance Security Group"

  # General Config
  vpc_id = "${aws_vpc.vpc.id}"

  # Allow SSH from Bastion host.
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bastion.id}"]
  }

  # Allow traffic for TCP 8300 (Server RPC)
  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow traffic for TCP 8301 (Serf LAN)
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow traffic for UDP 8301 (Serf LAN)
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow traffic for TCP 8400 (Consul RPC)
  ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow traffic for TCP 8500 (Consul Web UI)
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow traffic for TCP 8600 (Consul DNS Interface)
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow traffic for UDP 8600 (Consul DNS Interface)
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow incoming ICMP Echo.
  ingress {
    from_port   = 8
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tags
  tags {
    Name    = "${var.prefix}-vault_instance"
    Network = "private"
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*****************
  Vault Template
*****************/
data "template_file" "vault" {
  template = "${file("${path.root}/cloud-config/vault.tpl")}"

  # Template Variables
  vars {
    discovery_url = "${var.vault["discovery_url"]}"
  }
}

/*****************************
  Vault Launch Configuration
*****************************/
resource "aws_launch_configuration" "vault" {
  # General Config
  instance_type = "${var.vault["instance_type"]}"
  image_id      = "${data.aws_ami.coreos.id}"
  user_data     = "${data.template_file.vault.rendered}"
  key_name      = "${aws_key_pair.default.key_name}"

  # Networking
  associate_public_ip_address = true
  security_groups             = ["${aws_security_group.vault_instance.id}"]

  # Storage
  root_block_device {
    volume_size = 8
  }

  lifecycle {
    create_before_destroy = true
  }
}

/**************************
  Vault AutoScaling Group
**************************/
resource "aws_autoscaling_group" "vault" {
  name = "${var.prefix}-vault"

  # General Config
  launch_configuration = "${aws_launch_configuration.vault.name}"

  # Networking
  availability_zones  = ["${var.availability_zones}"]
  vpc_zone_identifier = ["${aws_subnet.private.*.id}"]

  # Cluster Size
  min_size         = "${var.vault["min_size"]}"
  max_size         = "${var.vault["max_size"]}"
  desired_capacity = "${var.vault["desired_capacity"]}"

  # Tags
  tag {
    key                 = "Name"
    value               = "${var.prefix}-vault"
    propagate_at_launch = true
  }

  tag {
    key                 = "Network"
    value               = "private"
    propagate_at_launch = true
  }
}

/*********************
  Vault LoadBalancer
*********************/
resource "aws_elb" "vault" {
  name = "${var.prefix}-vault"

  # Networking
  security_groups             = ["${aws_security_group.vault_loadbalancer.id}"]
  subnets                     = ["${aws_subnet.public.*.id}"]
  connection_draining         = true
  connection_draining_timeout = 400

  # Inbound Connections
  listener {
    instance_port     = 8200
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8200
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  # Healthcheck Config
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    target              = "HTTP:8200/v1/sys/health"
    interval            = 15
  }

  # Tags
  tags {
    Name        = "${var.prefix}-vault"
    Network     = "public"
    Application = "Vault"
    Environment = "${var.prefix}"
  }
}

/**********************************
  Vault Public ELB Security Group
**********************************/
resource "aws_security_group" "vault_loadbalancer" {
  name        = "${var.prefix}-vault_loadbalancer"
  description = "Vault Public Loadbalancer Security Group"

  # General Config
  vpc_id = "${aws_vpc.vpc.id}"

  # Allow HTTP access from everywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS access from everywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tags
  tags {
    Name        = "${var.prefix}-vault_loadbalancer"
    Network     = "public"
    Application = "Vault"
  }

  lifecycle {
    create_before_destroy = true
  }
}
