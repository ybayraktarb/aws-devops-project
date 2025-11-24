# Launch Template (Docker ile çalışacak şekilde revize edildi)
resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-docker-lt"
  image_id      = "ami-0df8c184d5f6ae949"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.kp.key_name # Jenkins SSH ile bağlanabilsin diye key ekledik

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  # User Data: Docker Kur ve Hazır Bekle
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install docker -y
              systemctl enable docker
              systemctl start docker
              # ECR Helper (Docker login için lazım olabilir)
              dnf install amazon-ecr-credential-helper -y
              EOF
  )
}

# Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { 
    path = "/" 
    timeout = 5
    interval = 10 
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
}
