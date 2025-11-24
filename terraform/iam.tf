# --- 1. Jenkins Rolü (ECR'a Yazabilir ve Okuyabilir) ---
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Jenkins'e "ECR Power User" yetkisi veriyoruz (Push yapabilsin diye)
resource "aws_iam_role_policy_attachment" "jenkins_ecr_policy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Jenkins Profil Kartı (EC2'ya takılacak)
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins_profile"
  role = aws_iam_role.jenkins_role.name
}

# --- 2. App Rolü (ECR'dan Sadece Okuyabilir) ---
resource "aws_iam_role" "app_role" {
  name = "app_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# App sunucusuna "ECR Read Only" yetkisi veriyoruz (Sadece Pull yapsın)
resource "aws_iam_role_policy_attachment" "app_ecr_policy" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "app_profile"
  role = aws_iam_role.app_role.name
}
