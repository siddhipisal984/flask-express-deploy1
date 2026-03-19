output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.single_ec2.public_ip
}

output "flask_url" {
  description = "Flask backend URL"
  value       = "http://${aws_instance.single_ec2.public_ip}:5000"
}

output "express_url" {
  description = "Express frontend URL"
  value       = "http://${aws_instance.single_ec2.public_ip}:3000"
}
