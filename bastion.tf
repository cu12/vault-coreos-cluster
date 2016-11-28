/*******************
  Bastion Template
*******************/
data "template_file" "bastion" {
  template = "${file("${path.root}/cloud-config/bastion.tpl")}"

  # Template Variables
  vars {
    prefix = "${var.prefix}"
    domain = "${var.domain}"
    size   = "${var.vault["size"]}"
  }
}

/**********
  Bastion
**********/
resource "aws_instance" "bastion" {
  # General Config
  instance_type = "${var.bastion["instance_type"]}"
  ami           = "${data.aws_ami.coreos.id}"
  user_data     = "${data.template_file.bastion.rendered}"
  key_name      = "${aws_key_pair.default.key_name}"

  # Networking
  subnet_id                   = "${aws_subnet.public.0.id}"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.bastion.id}"]

  # Storage
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  # Tags
  tags {
    Environment = "${var.prefix}"
    Name        = "${var.prefix}-bastion"
    Network     = "public"
  }
}
