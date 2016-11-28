/*************************
  Provider Configuration
*************************/
# Configure the AWS provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${lookup(var.aws_region, var.aws_account)}"
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
  most_recent = true

  filter {
    name   = "name"
    values = ["CoreOS-stable-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["595879546273"] # CoreOS
}

/*************************
  S3 Remote State Bucket
*************************/
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.prefix}-${var.aws_account}-terraform-state"

  # General Config
  versioning {
    enabled = true
  }

  # Security Config
  acl = "private"

  # Tags
  tags {
    Name = "${var.prefix}-${var.aws_account}-terraform-state"
  }

  tags {
    Access = "private"
  }

  tags {
    Environment = "${var.prefix}"
  }

  lifecycle {
    prevent_destroy = true
  }
}
