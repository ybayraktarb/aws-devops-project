# SSH Anahtarı Oluştur (Jenkins'e bağlanmak için lazım olacak)
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "my-key"
  public_key = tls_private_key.pk.public_key_openssh
}

# Özel Anahtarı bilgisayarına kaydet (mykey.pem)
resource "local_file" "ssh_key" {
  filename        = "${path.module}/mykey.pem"
  content         = tls_private_key.pk.private_key_pem
  file_permission = "0400"
}

# Jenkins Sunucusu
resource "aws_instance" "jenkins" {
  ami                    = "ami-0df8c184d5f6ae949" # Amazon Linux 2023
  instance_type          = "t3.small" # Jenkins RAM sever, micro yetmez!
  subnet_id              = aws_subnet.public_1.id # Public Subnet'te
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = aws_key_pair.kp.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name

  tags = { Name = "Jenkins-Server" }

  # User Data: Jenkins + Docker + Git Kurulumu
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              # Java Kurulumu (Jenkins Java ile çalışır)
              dnf install java-17-amazon-corretto -y
              
              # Jenkins Reposunu Ekle ve Kur
              wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              dnf install jenkins -y
              systemctl enable jenkins
              systemctl start jenkins

              # Docker Kurulumu
              dnf install docker -y
              systemctl enable docker
              systemctl start docker
              
              # Jenkins kullanıcısına Docker yetkisi ver (Sudo'suz çalışsın)
              usermod -aG docker jenkins
              
              # Git Kurulumu
              dnf install git -y
              EOF
}
