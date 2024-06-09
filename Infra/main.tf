terraform {
  backend "remote" {
    organization = "alex27_Org"
    workspaces {
      name = "hashi_Demo2-2"
    }
  }
}


/*
resource "aws_s3_bucket" "example2" {
  bucket = "my-terra-testbucket2-27123"

  tags = {
    Name        = "My bucket2"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "example3" {
  bucket = "my-tf-test-bucket3-27124"

  tags = {
    Name        = "My bucket3"
    Environment = "Dev"
  }
}
*/


resource "aws_vpc" "hashi_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "my_vpc"
  }
}
# Create an internet gateway
/* This is critical because it allows the VPC to connect to the internet. 
It also allows the internet to connect to the VPC. 
*/
resource "aws_internet_gateway" "hashi_IGW" {
  vpc_id = aws_vpc.hashi_vpc.id
  tags = {
    name = "my_IGW"
  }
}
# Create a custom route table. This one is pretty self explanatory
# It routes traffic into an out of the VPC
resource "aws_route_table" "hashi_route_table" {
  vpc_id = aws_vpc.hashi_vpc.id
  tags = {
    name = "my_route_table"
  }
}
# create route. "0.0.0.0/0" is a special CIDR notation that means "all IP addresses."
resource "aws_route" "hashi_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id  = aws_internet_gateway.hashi_IGW.id
  route_table_id = aws_route_table.hashi_route_table.id
}

# create a subnet - not necessarily defined as public or private
#to make it public I would need to associate it with a the public route table
resource "aws_subnet" "hashi_subnet1" {
  vpc_id = aws_vpc.hashi_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zone
  
  tags = {
    name = "my_subnet"
  }
}
resource "aws_route_table_association" "hashi_subnet_association" {
  subnet_id      = aws_subnet.hashi_subnet1.id
  route_table_id = aws_route_table.hashi_route_table.id
}

/* A security group acts as a virtual firewall for your instance to control inbound 
and outbound traffic. You can assign up to five security groups to the instance.
Ingress = Inbound 
Egress = Outbound 
*/
resource "aws_security_group" "hashi_SG" {
  name        = "sec_group"
  description = "security group for the EC2 instance"
  vpc_id      = aws_vpc.hashi_vpc.id
  ingress = [
    {
      description      = "https traffic"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0", aws_vpc.hashi_vpc.cidr_block]
      ipv6_cidr_blocks  = ["::/0"]
      prefix_list_ids   = []
      security_groups   = []
      self              = false
    },
    {
      description      = "http traffic"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0", aws_vpc.hashi_vpc.cidr_block]
      #cidr_blocks     = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      prefix_list_ids   = []
      security_groups   = []
      self              = false
    },
    {
      description      = "ssh"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0", aws_vpc.hashi_vpc.cidr_block]
      #cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks  = ["::/0"]
      prefix_list_ids   = []
      security_groups   = []
      self              = false
    }
  ]
  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "Outbound traffic rule"
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  tags = {
    name = "allow_web"
  }
}
# create a network interface with private ip from step 4
#this is important because it separates the instances from each other in vpc
resource "aws_network_interface" "public_net_interface" {
  subnet_id = aws_subnet.hashi_subnet1.id
  security_groups = [aws_security_group.hashi_SG.id]
}

# assign a elastic ip to the network interface created in step 7
#the elastic IP is important because you don't have to recreate it 
#every time you restart the instance like you would with a public IP 
resource "aws_eip" "hashi_eip" {
  vpc = true
  network_interface = aws_network_interface.public_net_interface.id
  associate_with_private_ip = aws_network_interface.public_net_interface.private_ip
  depends_on = [aws_internet_gateway.hashi_IGW, aws_instance.hashi_ec2]
}
# create an ubuntu server and install/enable apache2
resource "aws_instance" "hashi_ec2" {
  ami = var.ami
  instance_type = var.instance_type
  availability_zone = var.availability_zone
  key_name = "key_hashiDemo"
  user_data =  "${file("userData.sh")}"
  
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.public_net_interface.id
  }

#user_data = file("${path.module}/userData.sh")

  tags = {
    Name = "hashi_ec2"
  }

}
