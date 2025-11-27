# app.tf
#
# 1. Launch Template
# EC2 sunucuları nasıl ayağa kalkacak?
resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-docker-lt"
  image_id      = "ami-0df8c184d5f6ae949" # Amazon Linux 2023
  instance_type = "t3.micro"
  key_name      = aws_key_pair.kp.key_name 

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  # User Data: Docker Kur -> ECR Login Ol -> Uygulamayı Başlat
  # DİKKAT: Buradaki değişkenleri Terraform otomatik dolduracak
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install docker -y
              systemctl enable docker
              systemctl start docker
              
              # AWS CLI ile ECR'a Login Ol (Bölgeyi hardcode yaptık veya variable'dan alabilirsin)
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.app_repo.repository_url}
              
              # Uygulamayı Başlat (Veritabanı bilgilerini Environment Variable olarak veriyoruz)
              # Not: İlk başta repo boşsa docker pull hata verebilir, bu beklenen bir durumdur.
              # Pipeline ilk çalıştığında düzelecektir.
              docker run -d \
                --name flask-app \
                --restart always \
                -p 5000:5000 \
                -e DB_HOST="${aws_db_instance.default.address}" \
                -e DB_USER="${aws_db_instance.default.username}" \
                -e DB_PASSWORD="${aws_db_instance.default.password}" \
                -e DB_NAME="${aws_db_instance.default.db_name}" \
                ${aws_ecr_repository.app_repo.repository_url}:latest
              EOF
  )
  
  # Veritabanı ve ECR oluşmadan sunucu açmaya çalışma
  depends_on = [aws_db_instance.default, aws_ecr_repository.app_repo]
}

# 2. Load Balancer (ALB)
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# 3. Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 5000       # DÜZELTME: Flask 5000 portunda çalışıyor
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check { 
    path                = "/" 
    port                = "5000" # Sağlık kontrolünü de 5000'den yapsın
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10 
  }
}

# 4. Listener (80 -> 5000 yönlendirmesi)
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# 5. Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                = "app-asg"
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
  
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  health_check_type   = "ELB" # ALB sağlık kontrolüne göre instance kapatıp açsın
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "App-Server-ASG"
    propagate_at_launch = true
  }
}
