resource "aws_vpc" "vpc2" {
    provider = aws.central
  cidr_block = var.cidr_block_1
  enable_dns_hostnames = true
  tags = {
    "Name" = "${var.vpc1_name}"
  }
}

resource "aws_internet_gateway" "vpc2igw" {
    provider = aws.central
  vpc_id = aws_vpc.vpc2.id
  tags = {
    "Name" = "${var.vpc1_name}-igw"
  }
}

resource "aws_subnet" "vpc2publicsubnet" {
    provider = aws.central
    count = 2
    vpc_id = aws_vpc.vpc2.id
    cidr_block = element(var.vpc2publicsubnet_cidr_block,count.index)
    availability_zone = element(var.azs1,count.index)
    map_public_ip_on_launch = true
    tags = {
        "Name" = "${var.vpc1_name}-public${count.index+1}"
    }
}

resource "aws_route_table" "vpc2rt" {
    provider = aws.central
  vpc_id = aws_vpc.vpc2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc2igw.id
  }
  tags = {
    "Name" = "${var.vpc1_name}-rt"
    }
}

resource "aws_route_table_association" "publicsubnetvpc_2" {
    provider = aws.central
  count = 2
  subnet_id = element(aws_subnet.vpc2publicsubnet.*.id,count.index)
  route_table_id = aws_route_table.vpc2rt.id
}

resource "aws_route" "communication1" {
    provider = aws.central
    route_table_id = aws_route_table.vpc2rt.id
    destination_cidr_block = var.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.owner.id
}

resource "aws_security_group" "vpc2-sg" {
    provider = aws.central
  vpc_id = aws_vpc.vpc2.id
  name = "allow all rules"
  description = "allow inbound and outbound rules"
  tags = {
    "Name" = "${var.vpc1_name}-sg"
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

resource "aws_instance" "vpc2-instance" {
    provider = aws.central
  count =1  
  ami = var.ami1
  instance_type = var.instance_type1
  key_name = var.key_name1
  vpc_security_group_ids = [aws_security_group.vpc2-sg.id]
  subnet_id = element(aws_subnet.vpc2publicsubnet.*.id,count.index)
  private_ip = element(var.pip2,count.index)
  associate_public_ip_address = true
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  sudo systemctl start apache2
  EOF
  tags = {
   Name = "${var.vpc1_name}-server${count.index+1}"
  }


}
