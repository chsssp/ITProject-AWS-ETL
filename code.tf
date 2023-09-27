terraform {
  backend "s3" {
    bucket         = "terraform-st-track1"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "MyTerraform-ETL-VPC" {
  cidr_block = "10.0.0.0/23"
  tags = {
    Name = "MyETL-VPC"
  }
}

resource "aws_subnet" "MyTerraform-subnet" {
  vpc_id     = aws_vpc.MyTerraform-ETL-VPC.id
  cidr_block = "10.0.0.0/25"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "mySubnet"
  }
}

resource "aws_internet_gateway" "Internet_Gateway_vpc" {
  vpc_id = aws_vpc.MyTerraform-ETL-VPC.id

  tags = {
    Name = "MyETL_Internet_Gateway_vpc"
  }
}

resource "aws_route_table" "MyETL_Public_route_table" {
  vpc_id = aws_vpc.MyTerraform-ETL-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_Gateway_vpc.id
  }


  tags = {
    Name = "POC_Public_route_table"
  }
}

resource "aws_route_table_association" "POC_Public" {
  subnet_id      = aws_subnet.MyTerraform-subnet.id
  route_table_id = aws_route_table.MyETL_Public_route_table.id
}

resource "aws_security_group" "MyETL_Security_Group_web_access" {
  name        = "MyETL_Security_Group_web_access"
  description = "Allow TLS inbound traffic"
  vpc_id = aws_vpc.MyTerraform-ETL-VPC.id

  ingress {
    description = "Port 80 from VPC to connect application"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "Port 22 from VPC to connect instance"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "MyETL_Security_Group_web_access"
  }
}

resource "aws_instance" "myInstance" {
  ami             = "ami-02396cdd13e9a1257"
  instance_type   = "t2.micro"
  key_name        = "myetl"
  vpc_security_group_ids = [aws_security_group.MyETL_Security_Group_web_access.id]
  subnet_id       = aws_subnet.MyTerraform-subnet.id
  tags = {
    Name = "myETL_server"
  }
}