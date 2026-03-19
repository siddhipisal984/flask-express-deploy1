output "flask_backend_public_ip" {
  value = aws_instance.flask_backend.public_ip
}

output "express_frontend_public_ip" {
  value = aws_instance.express_frontend.public_ip
}

output "flask_url" {
  value = "http://${aws_instance.flask_backend.public_ip}:5000"
}

output "express_url" {
  value = "http://${aws_instance.express_frontend.public_ip}:3000"
}
