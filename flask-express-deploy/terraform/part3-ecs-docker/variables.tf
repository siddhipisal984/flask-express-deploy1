variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "Your AWS account ID"
  type        = string
}

variable "flask_image" {
  description = "ECR image URI for Flask backend"
  type        = string
  default     = ""
}

variable "express_image" {
  description = "ECR image URI for Express frontend"
  type        = string
  default     = ""
}
