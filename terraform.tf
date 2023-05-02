terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-1"
}

#creating the VPC

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "MYVPC"
  }
}

#public subnet

resource "aws_subnet" "publicsubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "PUBLICSUBNET"
  }
}

#private subnet

resource "aws_subnet" "privatesubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "PRIVATESUBNET"
  }
}

#internet gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "IGW"
  }
}

#public routetable

resource "aws_route_table" "publicroutetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "PUBLICROUTETABLE"
  }
}

#public routetable association

resource "aws_route_table_association" "publicroutetableassociation" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.publicroutetable.id
}

#Elastic IP

resource "aws_eip" "eip" {
  vpc      = true
  tags     = {
    Name   = "MYEIP"
  }
}

#Network Access Transfer

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.publicsubnet.id

  tags = {
    Name = "MYNAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

#private route table

resource "aws_route_table" "privateroutetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "PRIVATEROUTETABLE"
  }
}

#public security group

resource "aws_security_group" "publicsg" {
  name        = "publicsg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PUBLICSG"
  }
}

#private security group

resource "aws_security_group" "privatesg" {
  name        = "privatesg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["10.0.1.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PRIVATESG"
  }
}

#public instance

resource "aws_instance" "pub_instance" {
  ami                                                     = "ami-09080a875ef47d919"
  instance_type                                           = "t2.micro"
  availability_zone                                       = "ap-northeast-1d"
  associate_public_ip_address                             = "true"
  vpc_security_group_ids                                  = [aws_security_group.publicsg.id]
  subnet_id                                               = aws_subnet.publicsubnet.id 
  key_name                                                = "tokyo_pem_key_pair"
  
    tags = {
    Name = "HDFCBANK WEBSERVER"
  }
}

#private instance

resource "aws_instance" "pri_instance" {
  ami                                             = "ami-09080a875ef47d919"
  instance_type                                   = "t2.micro"
  availability_zone                               = "ap-northeast-1a"
  associate_public_ip_address         	          = "false"
  vpc_security_group_ids                          = [aws_security_group.privatesg.id]
  subnet_id                                       = aws_subnet.privatesubnet.id 
  key_name                                        = "tokyo_pem_key_pair"
  
    tags = {
    Name = "HDFCBANK APPSERVER"
  }
}
