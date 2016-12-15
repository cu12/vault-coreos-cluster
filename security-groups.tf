/*************************
  Bastion Security Group
*************************/
resource "aws_security_group" "bastion" {
  name        = "${var.prefix}-bastion"
  description = "Bastion Security Group"
  vpc_id      = "${aws_vpc.vpc.id}"

  # Tags
  tags {
    Name    = "${var.prefix}-bastion"
    Network = "public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "bastion-icmp" {
  security_group_id = "${aws_security_group.bastion.id}"
  type              = "ingress"
  from_port         = 8
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-ssh" {
  security_group_id = "${aws_security_group.bastion.id}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-egress" {
  security_group_id = "${aws_security_group.bastion.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

/***********************
  Vault Security Group
***********************/
resource "aws_security_group" "vault" {
  name        = "${var.prefix}-vault"
  description = "Vault Security Group"
  vpc_id      = "${aws_vpc.vpc.id}"

  # Tags
  tags {
    Name    = "${var.prefix}-vault"
    Network = "private"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "vault-icmp" {
  security_group_id = "${aws_security_group.vault.id}"
  type              = "ingress"
  from_port         = 8
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault-ssh" {
  security_group_id        = "${aws_security_group.vault.id}"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "vault-consul-server-rpc" {
  security_group_id = "${aws_security_group.vault.id}"
  type              = "ingress"
  from_port         = 8300
  to_port           = 8300
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "vault-consul-serf-lan-tcp" {
  security_group_id = "${aws_security_group.vault.id}"
  type              = "ingress"
  from_port         = 8301
  to_port           = 8301
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "vault-consul-serf-lan-udp" {
  security_group_id = "${aws_security_group.vault.id}"
  type              = "ingress"
  from_port         = 8301
  to_port           = 8301
  protocol          = "udp"
  self              = true
}

resource "aws_security_group_rule" "vault-consul-rpc" {
  security_group_id = "${aws_security_group.vault.id}"
  type              = "ingress"
  from_port         = 8400
  to_port           = 8400
  protocol          = "udp"
  self              = true
}

resource "aws_security_group_rule" "vault-elb" {
  security_group_id        = "${aws_security_group.vault.id}"
  type                     = "ingress"
  from_port                = 8200
  to_port                  = 8200
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.vault_loadbalancer.id}"
}

resource "aws_security_group_rule" "vault-egress" {
  security_group_id = "${aws_security_group.vault.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

/***************************
  Vault ELB Security Group
***************************/
resource "aws_security_group" "vault_loadbalancer" {
  name_prefix = "${var.prefix}-vault_loadbalancer"
  description = "Vault Loadbalancer Security Group"
  vpc_id      = "${aws_vpc.vpc.id}"

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

resource "aws_security_group_rule" "vault-loadbalancer-http" {
  security_group_id = "${aws_security_group.vault_loadbalancer.id}"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault-loadbalancer-https" {
  security_group_id = "${aws_security_group.vault_loadbalancer.id}"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vault-loadbalancer-egress" {
  security_group_id = "${aws_security_group.vault_loadbalancer.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
