variable "aws_region" {
  type = "map"

  default = {
    central = "eu-west-1"
  }
}

/******************
  Default AZ List
******************/
variable "availability_zones" {
  type    = "list"
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

/****************
  VPC Variables
****************/
# Size of VPC network
variable "vpc_cidr" {
  default = "10.64.0.0/16"
}

/************************
  Bastion Configuration
************************/
variable "bastion" {
  type = "map"

  default = {
    # General Config
    instance_type = "t2.micro"
  }
}

/**********************
  Vault Configuration
**********************/
variable "vault" {
  type = "map"

  default = {
    # General Config
    instance_type = "t2.small"
    discovery_url = "https://discovery.etcd.io/c7eecbb7f0e7f72388f59f119d75d1e7"

    # Cluster Size
    min_size         = 5
    max_size         = 5
    desired_capacity = 5
  }
}

# Empty Variables
variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_account" {}

variable "prefix" {}

variable "ssh_public_key" {}
