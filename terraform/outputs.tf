output "ecr_repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "load_balancer_dns" {
  value = aws_lb.app_lb.dns_name
}

output "db_endpoint" {
  value = aws_db_instance.default.address
}
