provider "aws" {
  region = "us-east-1"
  # Profil kullanıyorsan buraya ekleyebilirsin: profile = "default"
}

terraform {
  required_version = ">= 1.0" # Terraform CLI versiyon kısıtlaması (Öneri)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # İleride state dosyasını S3'te tutmak istersen "backend" bloğu buraya gelecek.
}
