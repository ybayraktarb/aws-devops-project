# 1. ALB SG (İnternete Açık)
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow HTTP traffic"

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
}

# 2. Jenkins SG (Sadece 8080 ve SSH)
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow Jenkins and SSH"

  # Jenkins Arayüzü (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Gerçek hayatta sadece Kendi IP'n olmalı
  }
  
  # SSH (22)
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
}

# 3. App Server SG (Sadece ALB'den ve Jenkins'ten gelen trafiği al)
resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  vpc_id      = aws_vpc.main.id
  
  # Load Balancer'dan gelen trafik
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Jenkins'ten gelen SSH trafiği (Deployment için)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Database SG
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id] # Sadece App sunucuları
  }
}
