/*************************
  Bastion Security Group
*************************/

# Allow SSH access to Bastion host
resource "aws_security_group" "bastion" {
  name        = "${var.prefix}-bastion"
  description = "Bastion Security Group"

  # General Config
  vpc_id = "${aws_vpc.vpc.id}"

  # Allows traffic from the SG itself for TCP.
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  # Allows traffic from the SG itself for UDP.
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    self      = true
  }

  # Allow ICMP echo from everywhere
  ingress {
    from_port   = 8
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH access from Office IP address
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["89.245.151.228/32"]
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
    Name    = "${var.prefix}-bastion"
    Network = "public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

/*******************************
  Bastion Launch Configuration
*******************************/
resource "aws_launch_configuration" "bastion" {
  # General Config
  instance_type = "${var.bastion["instance_type"]}"
  image_id      = "${data.aws_ami.coreos.id}"
  key_name      = "${aws_key_pair.default.key_name}"

  # Networking
  associate_public_ip_address = true
  security_groups             = ["${aws_security_group.bastion.id}"]

  # Storage
  root_block_device {
    volume_size = 8
  }

  lifecycle {
    create_before_destroy = true
  }
}

/****************************
  Bastion AutoScaling Group
****************************/
resource "aws_autoscaling_group" "bastion" {
  name = "${var.prefix}-bastion-${aws_launch_configuration.bastion.name}"

  # General Config
  launch_configuration = "${aws_launch_configuration.bastion.name}"

  # Networking
  availability_zones  = ["${element(var.availability_zones, 0)}"]
  vpc_zone_identifier = ["${aws_subnet.public.0.id}"]

  # Cluster Size
  min_size         = "1"
  max_size         = "1"
  desired_capacity = "1"

  # Tags
  tag {
    key                 = "Name"
    value               = "${var.prefix}-bastion"
    propagate_at_launch = true
  }

  tag {
    key                 = "Network"
    value               = "public"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
