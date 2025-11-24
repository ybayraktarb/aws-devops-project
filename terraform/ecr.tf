resource "aws_ecr_repository" "app_repo" {
  name                 = "my-flask-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Terraform destroy deyince içindeki imajlarla birlikte silinsin

  image_scanning_configuration {
    scan_on_push = true
  }
}
