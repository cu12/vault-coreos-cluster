/*************************
  Provider Configuration
*************************/
# Configure the AWS provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

/**********
  SSH Key
**********/
resource "aws_key_pair" "default" {
  key_name   = "${var.prefix}-${var.aws_account}"
  public_key = "${var.ssh_public_key}"
}

/********************
  AMI Configuration
********************/
data "aws_ami" "coreos" {
  filter {
    name   = "name"
    values = ["CoreOS-stable-1185.5.0-hvm"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["595879546273"] # CoreOS
}
