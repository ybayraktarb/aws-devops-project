# 1. ALB SG (İnternete Açık - Load Balancer)
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  vpc_id      = aws_vpc.main.id # vpc.tf dosyasındaki isme referans
  description = "Allow HTTP traffic from internet"

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

  tags = { Name = "alb-security-group" }
}

# 2. Jenkins SG (Yönetim Sunucusu)
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow Jenkins (8080) and SSH (22)"

  # Jenkins Arayüzü
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Production'da buraya kendi IP adresini yazmalısın!
  }
  
  # SSH Erişimi (Debug için)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jenkins-security-group" }
}

# 3. App/ECS SG (Sadece ALB'den gelen trafiği kabul et)
resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow traffic from ALB only"
  
  # Load Balancer'dan gelen trafik (Flask Portu: 5000)
  ingress {
    from_port       = 5000 
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Not: SSH (22) kuralı kaldırıldı çünkü Fargate kullanıyoruz.
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Konteynerlar dışarıdan paket indirebilsin (NAT üzerinden)
  }

  tags = { Name = "ecs-app-security-group" }
}

# 4. Database SG (Sadece App SG'den gelen trafiği kabul et)
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow DB traffic from App Layer"

  ingress {
    from_port       = 3306 # MySQL Portu (PostgreSQL kullanacaksan 5432 yapmalısın)
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id] # Sadece ECS görevleri erişebilir
  }
  
  tags = { Name = "database-security-group" }
}
