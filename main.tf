terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "5.73.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public_route.id
  subnet_id = aws_subnet.public_subnet.id
}

resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.private_route.id
  subnet_id = aws_subnet.private_subnet.id
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "mykey" {
  key_name = "sharukh"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_instance" "ec2" {
  count = var.instance_count
  ami = var.amis[count.index]
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private_subnet.id
  key_name = aws_key_pair.mykey.key_name
  security_groups = [aws_security_group.sg.id]
  associate_public_ip_address = true

  user_data = file("script.sh")

  tags = {
    Name = "sharukh-${count.index+1}"
  }
}

output "public_ip" {
    value = aws_instance.ec2[*].public_ip
}
