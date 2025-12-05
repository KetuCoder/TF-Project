provider "aws" {
  region = var.region
}

# -------------------
# VPC
# -------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# -------------------
# Subnets
# -------------------
resource "aws_subnet" "public1" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.main.id
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public2" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.main.id
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "private1" {
  cidr_block = "10.0.3.0/24"
  vpc_id     = aws_vpc.main.id
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private2" {
  cidr_block = "10.0.4.0/24"
  vpc_id     = aws_vpc.main.id
  availability_zone = "us-east-1b"
}

# -------------------
# NAT Gateway
# -------------------
resource "aws_eip" "nat" {}
resource "aws_nat_gateway" "nat" {
  subnet_id     = aws_subnet.public1.id
  allocation_id = aws_eip.nat.id
}

# -------------------
# Route Tables
# -------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}


resource "aws_route_table_association" "p1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "p2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}


resource "aws_route_table_association" "pr1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "pr2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}


# -------------------
# Security Groups
# -------------------
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id
  ingress { from_port=80 to_port=80 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  egress  { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id
  ingress { from_port=8080 to_port=8080 protocol="tcp" security_groups=[aws_security_group.alb_sg.id] }
  egress  { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

# -------------------
# IAM Role (SSM)
# -------------------
resource "aws_iam_role" "ec2_role" {
  assume_role_policy = jsonencode({
    Version="2012-10-17"
    Statement=[{Effect="Allow", Principal={Service="ec2.amazonaws.com"}, Action="sts:AssumeRole"}]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "profile" {
  role = aws_iam_role.ec2_role.name
}

# -------------------
# ALB + Target Group
# -------------------
resource "aws_lb" "alb" {
  subnets         = [aws_subnet.public1.id, aws_subnet.public2.id]
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { path = "/health" }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# -------------------
# Launch Template
# -------------------
resource "aws_launch_template" "lt" {
  image_id      = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  iam_instance_profile { name = aws_iam_instance_profile.profile.name }
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<EOF
#!/bin/bash
yum install -y python3
pip3 install flask
cat << APP > /home/ec2-user/app.py
from flask import Flask
app = Flask(__name__)
@app.route("/") 
def home(): return "Hello from ASG!"
@app.route("/health") 
def h(): return "ok"
app.run(host="0.0.0.0", port=8080)
APP
python3 /home/ec2-user/app.py
EOF
)
}

# -------------------
# Auto Scaling Group
# -------------------
resource "aws_autoscaling_group" "asg" {
  desired_capacity = 2
  max_size         = 2
  min_size         = 2
  vpc_zone_identifier = [aws_subnet.private1.id, aws_subnet.private2.id]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]
}
