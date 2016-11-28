/****************
  VPC Variables
****************/
# Size of VPC network
variable "vpc_cidr" {
  default = "10.64.0.0/16"
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "availability_zones" {
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

/************************
  Bastion Configuration
************************/
variable "bastion" {
  default = {
    # General Config
    instance_type = "t2.micro"
  }
}

/**********************
  Vault Configuration
**********************/
variable "vault" {
  default = {
    # General Config
    version       = "0.6.2"
    instance_type = "t2.small"

    # Cluster Size
    size = 5
  }
}

variable "consul_version" {
  default = "0.7.1"
}

# Empty Variables
variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_account" {}

variable "prefix" {}

variable "domain" {}

variable "vault_address" {}

variable "ssh_public_key" {}
