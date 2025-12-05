# Launch Template
resource "aws_launch_template" "app_lt" {
  name          = "app-lt"
  image_id      = "ami-0c2b8ca1dad447f8a" # Amazon Linux 2 (replace with region-specific AMI)
  instance_type = var.instance_type
  user_data     = file("userdata.sh")
  iam_instance_profile { name = aws_iam_instance_profile.ec2_profile.name }
  security_group_names = [aws_security_group.ec2_sg.name]
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.private1.id, aws_subnet.private2.id]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]
  health_check_type = "ELB"
  force_delete      = true
}
