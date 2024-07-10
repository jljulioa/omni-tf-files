terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


resource "aws_vpc" "trfm_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "trfm_vpc"
  }
}

# Public Subnet in us-east-1a
resource "aws_subnet" "trfm_public_subnet_a" {
  vpc_id                  = aws_vpc.trfm_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "trfm_public_subnet_a"
  }
}

# Public Subnet in us-east-1b
resource "aws_subnet" "trfm_public_subnet_b" {
  vpc_id                  = aws_vpc.trfm_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "trfm_public_subnet_b"
  }
}

# Private Subnet in us-east-1a
resource "aws_subnet" "trfm_private_subnet_a" {
  vpc_id            = aws_vpc.trfm_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "trfm_private_subnet_a"
  }
}

# Private Subnet in us-east-1b
resource "aws_subnet" "trfm_private_subnet_b" {
  vpc_id            = aws_vpc.trfm_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "trfm_private_subnet_b"
  }
}

resource "aws_internet_gateway" "trfm_igw" {
  vpc_id = aws_vpc.trfm_vpc.id
  tags = {
    Name = "trfm_igw"
  }
}

resource "aws_route_table" "trfm_public_rt" {
  vpc_id = aws_vpc.trfm_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.trfm_igw.id
  }
  tags = {
    Name = "trfm_public_rt"
  }
}

resource "aws_route_table_association" "trfm_public_rta_a" {
  subnet_id      = aws_subnet.trfm_public_subnet_a.id
  route_table_id = aws_route_table.trfm_public_rt.id
}

resource "aws_route_table_association" "trfm_public_rta_b" {
  subnet_id      = aws_subnet.trfm_public_subnet_b.id
  route_table_id = aws_route_table.trfm_public_rt.id
}

resource "aws_eip" "trfm_nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "trfm_nat_gw" {
  allocation_id = aws_eip.trfm_nat_eip.id
  subnet_id     = aws_subnet.trfm_public_subnet_a.id
  tags = {
    Name = "trfm_nat_gw"
  }
}

resource "aws_route_table" "trfm_private_rt" {
  vpc_id = aws_vpc.trfm_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.trfm_nat_gw.id
  }
  tags = {
    Name = "trfm_private_rt"
  }
}

resource "aws_route_table_association" "trfm_private_rta_a" {
  subnet_id      = aws_subnet.trfm_private_subnet_a.id
  route_table_id = aws_route_table.trfm_private_rt.id
}

resource "aws_route_table_association" "trfm_private_rta_b" {
  subnet_id      = aws_subnet.trfm_private_subnet_b.id
  route_table_id = aws_route_table.trfm_private_rt.id
}

resource "aws_security_group" "trfm_sg" {
  name   = "trfm_sg"
  vpc_id = aws_vpc.trfm_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.trfm_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "trfm_sg"
  }
}

resource "aws_security_group" "trfm_alb_sg" {
  name   = "trfm_alb_sg"
  vpc_id = aws_vpc.trfm_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "trfm_alb_sg"
  }
}

resource "aws_instance" "trfm_private_ec2_a" {
  ami                    = "ami-076c26b5f1e7898ab"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.trfm_private_subnet_a.id
  vpc_security_group_ids = [aws_security_group.trfm_sg.id]
  tags = {
    Name = "trfm_private_ec2_a"
  }
}

resource "aws_instance" "trfm_private_ec2_b" {
  ami                    = "ami-076c26b5f1e7898ab"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.trfm_private_subnet_b.id
  vpc_security_group_ids = [aws_security_group.trfm_sg.id]
  tags = {
    Name = "trfm_private_ec2_b"
  }
}

resource "aws_lb" "trfm_elb" {
  name               = "trfmelb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.trfm_alb_sg.id]
  subnets            = [
    aws_subnet.trfm_public_subnet_a.id,
    aws_subnet.trfm_public_subnet_b.id,
  ]

  enable_deletion_protection = false

  tags = {
    Name = "trfm_elb"
  }
}

resource "aws_lb_target_group" "trfm_elb_tg" {
  name        = "trfmelbtg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.trfm_vpc.id
  target_type = "instance"

  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 5
  }

  tags = {
    Name = "trfm_elb_tg"
  }
}

resource "aws_lb_listener" "trfm_elb_listener" {
  load_balancer_arn = aws_lb.trfm_elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.trfm_elb_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "trfm_private_ec2_a_attachment" {
  target_group_arn = aws_lb_target_group.trfm_elb_tg.arn
  target_id        = aws_instance.trfm_private_ec2_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "trfm_private_ec2_b_attachment" {
  target_group_arn = aws_lb_target_group.trfm_elb_tg.arn
  target_id        = aws_instance.trfm_private_ec2_b.id
  port             = 80
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.trfm_vpc.id
  service_name    = "com.amazonaws.us-east-1.s3"
  route_table_ids = [aws_route_table.trfm_private_rt.id]
}

resource "null_resource" "create_instance_connect_endpoints" {
  provisioner "local-exec" {
    command = <<EOT
      aws ec2 create-instance-connect-endpoint --subnet-id "${aws_subnet.trfm_private_subnet_a.id}"
    EOT
  }
  depends_on = [aws_instance.trfm_private_ec2_a]
}
