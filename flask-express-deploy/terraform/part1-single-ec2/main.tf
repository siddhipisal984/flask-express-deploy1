terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # S3 backend for state management (uncomment and fill after creating bucket)
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "part1/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

# ---- Security Group ----
resource "aws_security_group" "single_ec2_sg" {
  name        = "flask-express-single-sg"
  description = "Allow SSH, Flask port 5000, Express port 3000"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask backend"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Express frontend"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flask-express-single-sg"
  }
}

# ---- EC2 Instance ----
resource "aws_instance" "single_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.single_ec2_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y

    # Install Python
    apt-get install -y python3 python3-pip python3-venv

    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs

    # Install git
    apt-get install -y git

    # Clone repo
    cd /home/ubuntu
    git clone https://github.com/siddhipisal984/flask-express-deploy1.git
    cd flask-express-deploy1

    # Setup Flask
    cd flask-express-deploy/backend
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate

    # Start Flask in background
    nohup /home/ubuntu/flask-express-deploy1/flask-express-deploy/backend/venv/bin/gunicorn \
      --bind 0.0.0.0:5000 \
      --chdir /home/ubuntu/flask-express-deploy1/flask-express-deploy/backend \
      app:app > /var/log/flask.log 2>&1 &

    # Setup Express
    cd /home/ubuntu/flask-express-deploy1/flask-express-deploy/frontend
    npm install --production

    # Start Express in background
    FLASK_URL=http://localhost:5000 nohup node server.js > /var/log/express.log 2>&1 &
  EOF

  tags = {
    Name = "flask-express-single-ec2"
  }
}
