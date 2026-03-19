variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI ID"
  default     = "ami-0c7217cdde317cfec" # us-east-1 Ubuntu 22.04
}
