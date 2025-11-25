# jenkins.tf

# --- SSH Anahtarı Otomasyonu ---
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "jenkins-key" # İsim çakışması olmaması için biraz özelleştirdim
  public_key = tls_private_key.pk.public_key_openssh
}

# Özel Anahtarı bilgisayarına kaydet (jenkins-key.pem)
resource "local_file" "ssh_key" {
  filename        = "${path.module}/jenkins-key.pem"
  content         = tls_private_key.pk.private_key_pem
  file_permission = "0400"
}

# --- Jenkins Sunucusu ---
resource "aws_instance" "jenkins" {
  ami                    = "ami-0df8c184d5f6ae949" # Amazon Linux 2023 (US-East-1)
  instance_type          = "t3.small"              # 2GB RAM (Jenkins + Docker build için ideal)
  subnet_id              = aws_subnet.public_1.id  # Public Subnet'te olmalı
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = aws_key_pair.kp.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name

  tags = { Name = "Jenkins-Server" }

  # User Data: Sıralama Kritik!
  # Jenkins'i en son başlatıyoruz ki 'docker' grubu üyeliğini algılasın.
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              
              # 1. Java Kurulumu (Jenkins Runtime)
              dnf install java-17-amazon-corretto -y
              
              # 2. Jenkins Kurulumu (Ama başlatma yok!)
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              dnf install jenkins -y
              
              # 3. Docker Kurulumu ve Başlatılması
              dnf install docker -y
              systemctl enable docker
              systemctl start docker
              
              # 4. Git Kurulumu
              dnf install git -y
              
              # 5. Yetki Ayarı (Kritik Adım)
              # Jenkins kullanıcısını Docker grubuna ekle
              usermod -aG docker jenkins
              
              # 6. Jenkins Servisini Başlat
              # Grup değişikliğinden SONRA başlattığımız için Docker socket'e erişebilir.
              systemctl enable jenkins
              systemctl start jenkins
              EOF
}
