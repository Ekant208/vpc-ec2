#VPC

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"
    tags = {
    Name = "ekantvpc"
  }
}
#subnets

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
availability_zone = "us-east-1a"
   cidr_block = "10.0.0.0/25"
  tags = {
   Name = "ekantvpcprivate"
  }
}

resource "aws_subnet" "main2" {
  vpc_id     = aws_vpc.main.id
availability_zone = "us-east-1a"
 cidr_block = "10.0.0.192/26"
  tags = {
   Name = "ekantvpcpublic"
  }
}
# route table

resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.main.id
}
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "10.0.0.128/26"
#     gateway_id = aws_internet_gateway.main.id
#   }
  

  tags = {
    Name = "ekantvpc"
  }
}

#IG
# resource "aws_internet_gateway_attachment" "main" {
#   internet_gateway_id = aws_internet_gateway.main.id
#   vpc_id              = aws_vpc.main.id
# }
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ekantvpc"
  }
}
#acl
resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main.id

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.0.0/24"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/24"
    from_port  = 0
    to_port    = 65535
  }

  tags = {
    Name = "Ekantvpc"
  }
}

resource "aws_network_acl_association" "main" {
  network_acl_id = aws_network_acl.main.id
  subnet_id      = aws_subnet.main.id
}
resource "aws_network_acl_association" "main2" {
  network_acl_id = aws_network_acl.main.id
  subnet_id      = aws_subnet.main2.id
}

#IAM
resource "aws_iam_policy" "main" {
  name        = "test_policy"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "FirstStatement",
      "Effect": "Allow",
       "Action": "s3:*",
    "Resource": "*"
    },
    {
      "Sid": "SecondStatement",
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
    }
  ]
})
}



# resource "aws_iam_role" "role" {
#   name               = "test-role"
#   assume_role_policy = aws_iam_policy.main.policy
# }



# resource "aws_iam_policy_attachment" "test-attach" {
#   name       = "test-attachment"
#   roles      = [aws_iam_role.role.name]
#   policy_arn = aws_iam_policy.main.arn
# }

#s3

resource "aws_s3_bucket" "example" {
  bucket = "ekant"

  tags = {
    Name        = "ekant"
  }
}

#keypair

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}

#ec2

# Create an AMI that will start a machine whose root device is backed by
# an EBS volume populated from a snapshot. We assume that such a snapshot
# already exists with the id "snap-xxxxxxxx".
# resource "aws_ami" "example" {
#   name                = "terraform-example"
#   # virtualization_type = "hvm"
#   # root_device_name    = "/dev/xvda"
#   # Enforce usage of IMDSv2. You can safely remove this line if your application explicitly doesn't support it.
#   # ebs_block_device {
#   #   device_name = "/dev/xvda"
#   #   snapshot_id = "snap-xxxxxxxx"
#   #   volume_size = 8
#   # }
# }

resource "aws_instance" "web" {
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.main.id
  ami           = "ami-0468ac5f57c53fbad"
    network_interface {
    network_interface_id = aws_network_interface.test.id
    device_index         = 0
  }
  #  ebs_block_device = aws_ebs_volume.example.id
 security_groups = [aws_security_group.example.id]
  tags = {
    Name = "HelloWorld"
  }
}
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.main.id
  private_ips     = ["10.0.0.27"]
  security_groups = [aws_security_group.example.id]

  # attachment {
  #   instance     = aws_instance.web.id
  #   device_index = 1
  # }
}
resource "aws_ebs_volume" "example" {
  availability_zone = "us-east-1a"
  size              = 40

  tags = {
    Name = "HelloWorld"
  }
}
#security_groups 

resource "aws_security_group" "example" {
  # ... other configuration ...
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

 ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    #prefix_list_ids = [aws_vpc_endpoint.my_endpoint.prefix_list_id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
   # prefix_list_ids = [aws_vpc_endpoint.my_endpoint.prefix_list_id]
  }
}



#AMI










