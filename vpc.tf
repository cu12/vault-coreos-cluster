/********************
  VPC Configuration
********************/
resource "aws_vpc" "vpc" {
  # General Config
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags
  tags {
    Name = "${var.prefix}-${var.aws_account}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

/***********************
  Subnet Configuration
***********************/
resource "aws_subnet" "public" {
  count = "${length(compact(var.availability_zones))}"

  # General Config
  vpc_id = "${aws_vpc.vpc.id}"

  # Networking
  map_public_ip_on_launch = true
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 8, count.index )}"
  availability_zone       = "${element(var.availability_zones, count.index)}"

  # Tags
  tags {
    Name    = "${var.prefix}-public-${element(var.availability_zones, count.index)}"
    Network = "public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "private" {
  count = "${length(compact(var.availability_zones))}"

  # General Config
  vpc_id = "${aws_vpc.vpc.id}"

  # Networking
  cidr_block        = "${cidrsubnet(var.vpc_cidr, 8, count.index+128 )}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  # Tags
  tags {
    Name    = "${var.prefix}-private-${element(var.availability_zones, count.index)}"
    Network = "private"
  }

  lifecycle {
    create_before_destroy = true
  }
}

/**********
  Routing
**********/
resource "aws_route_table" "public" {
  count = "${length(compact(var.availability_zones))}"

  # General Config
  vpc_id = "${aws_vpc.vpc.id}"

  # Route
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  # Tags
  tags {
    Name    = "${var.prefix}-public-${element(var.availability_zones, count.index)}"
    Network = "public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  count = "${length(compact(var.availability_zones))}"

  # Networking
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "private" {
  count = "${length(compact(var.availability_zones))}"

  # General Config
  vpc_id = "${aws_vpc.vpc.id}"

  # Route
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.private.*.id, count.index)}"
  }

  # Tags
  tags {
    Name    = "${var.prefix}-private-${element(var.availability_zones, count.index)}"
    Network = "private"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "private" {
  count = "${length(compact(var.availability_zones))}"

  # Networking
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"

  lifecycle {
    create_before_destroy = true
  }
}

/*******************
  Internet Gateway
********************/
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.vpc.id}"

  # Tags
  tags {
    Name    = "${var.prefix}-${var.aws_account}"
    Network = "public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

/**************
  NAT Gateway
**************/
resource "aws_eip" "nat" {
  count = "${length(compact(var.availability_zones))}"

  vpc = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "private" {
  count = "${length(compact(var.availability_zones))}"

  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"

  # Define explicit dependency on the Internet Gateway
  depends_on = ["aws_internet_gateway.default"]

  lifecycle {
    create_before_destroy = true
  }
}
