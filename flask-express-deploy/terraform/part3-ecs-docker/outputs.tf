output "alb_dns_name" {
  description = "Application Load Balancer DNS - open this in browser"
  value       = "http://${aws_lb.main.dns_name}"
}

output "flask_ecr_url" {
  description = "ECR URL for Flask backend"
  value       = aws_ecr_repository.flask_backend.repository_url
}

output "express_ecr_url" {
  description = "ECR URL for Express frontend"
  value       = aws_ecr_repository.express_frontend.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}
