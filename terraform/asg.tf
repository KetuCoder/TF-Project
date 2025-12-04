resource "aws_launch_template" "app" {
  name          = "app-lt"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  user_data     = file("userdata.sh")
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_role.name
  }
  security_group_names = [aws_security_group.ec2_sg.name]
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_role" {
  name = "ec2-role-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 2
  vpc_zone_identifier  = aws_subnet.private[*].id
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.app_tg.arn]
  health_check_type = "ELB"
  force_delete      = true
}
