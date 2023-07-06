provider "aws" {
    region = "us-west-1"
}

variable "subnet_cidr_block" {}
variable "vpc_cidr_block" {}
variable "AZ" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "ami" {}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id 
    cidr_block = var.subnet_cidr_block
    availability_zone = var.AZ
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}

resource "aws_route_table_association" "ass-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
}

resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [var.my_ip]
        prefix_list_ids = []
    }

    tags = {
        Name: "${var.env_prefix}-sg"
    }
}

resource "aws_instance" "myapp-server" {
    ami                         = var.ami
    instance_type               = var.instance_type
    subnet_id                   = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids      = [aws_security_group.myapp-sg.id]
    availability_zone           = var.AZ
    associate_public_ip_address = true
    key_name                    = "test-py"

    tags = {
        Name: "${var.env_prefix}-server"
    }

#     provisioner "local-exec" {
#     working_dir = "/home/ziad/projects/ansible/Run-Docker-applications"
#     command = "ansible-playbook --inventory ${self.public_ip}, --private-key ${test-py} --user ec2-user deploy-docker-ec2-user.yaml"
#   } 

}

resource "null_resource" "configure_server" {
    triggers = {
        trigger = aws_instance.myapp-server.public_ip
  }

    provisioner "local-exec" {
        working_dir = "/home/ziad/projects/ansible/Run-Docker-applications"
        command = "ansible-playbook --inventory ${aws_instance.myapp-server.public_ip}, --private-key=test-py --user ec2-user deploy-docker-ec2-user.yaml"
    }
}
   

output "server-ip" {
    value = aws_instance.myapp-server.public_ip
}


# resource "aws_instance" "myapp-server-two" {
#     ami                         = var.ami
#     instance_type               = var.instance_type
#     subnet_id                   = aws_subnet.myapp-subnet-1.id
#     vpc_security_group_ids      = [aws_security_group.myapp-sg.id]
#     availability_zone           = var.AZ
#     associate_public_ip_address = true
#     key_name                    = "test-py"

#     tags = {
#         Name: "${var.env_prefix}-server-two"
#     }
# }
