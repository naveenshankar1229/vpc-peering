resource "aws_vpc" "vpc1" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }

}

resource "aws_subnet" "public1" {
  count = 2
  vpc_id = aws_vpc.vpc1.id
  cidr_block = element(var.public1_cidr_block,count.index)
  availability_zone = element(var.azs,count.index)
  map_public_ip_on_launch = true
  tags = {
    "Name"= "${var.vpc_name}-public${count.index+1}"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    "Name" = "${var.vpc_name}-rt"
  }
}

resource "aws_route_table_association" "publicsubnet1" {
    count=2
    subnet_id = element(aws_subnet.public1.*.id,count.index)
    route_table_id = aws_route_table.rt.id

}

resource "aws_route" "communication" {
  route_table_id = aws_route_table.rt.id
  destination_cidr_block = var.cidr_block_1
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.id
}

resource "aws_security_group" "test-sg" {
  vpc_id = aws_vpc.vpc1.id
  name = "allow all rules"
  description = "allow inbound and outbound rules"
  tags = {
    "Name" = "${var.vpc_name}-sg"
  }
  ingress {
    description = "allow all rules"
    to_port = 0
    from_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "allow all rules"
    to_port = 0
    from_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_instance" "vpc1-instance" {
  count =1
  ami = var.ami
  key_name = var.key
  instance_type = var.instance
  vpc_security_group_ids = [aws_security_group.test-sg.id]
  subnet_id = element(aws_subnet.public1.*.id,count.index)
  private_ip = element(var.pip,count.index)
  associate_public_ip_address = true
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  sudo systemctl start apache2
  EOF
  tags = {
    "Name" = "${var.vpc_name}-server"
  }

}
