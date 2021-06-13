
provider "aws" {
  region = 
  access_key = 
  secret_key = 
}
#create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = ""
  tags = {
    Name = "production"
  }
}
#create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}
#create route table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = ""
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = ""
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}
#create subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = ""
  availability_zone = ""

  tags = {
    Name = "prod-subnet"
  }
}
#join subnet to route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}
#create sec grp and assign rights
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
  
  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }
  
  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}
#create a network interfae
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = [""]
  security_groups = [aws_security_group.allow_web.id]

 
}
#assign elastic ip
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = ""
  depends_on = [
    aws_internet_gateway.gw
  ]
}
#create ec2
resource "aws_instance" "web-server-instance" {
  ami = ""
  instance_type = ""
  availability_zone = ""
  key_name = ""
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id

  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo Hiiiii, I'm a Web server > /var/www/html/index.html'
              EOF
  tags = {
    Name = "web-server"
  }
}

