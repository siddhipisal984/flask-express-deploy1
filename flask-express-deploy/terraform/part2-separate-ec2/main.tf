terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "part2/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

# ---- VPC ----
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "flask-express-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "flask-express-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags                    = { Name = "flask-express-subnet" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "flask-express-rt" }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

# ---- Security Group: Flask Backend ----
resource "aws_security_group" "backend_sg" {
  name   = "flask-backend-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "Flask from frontend SG"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "flask-backend-sg" }
}

# ---- Security Group: Express Frontend ----
resource "aws_security_group" "frontend_sg" {
  name   = "express-frontend-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Express public access"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "express-frontend-sg" }
}

# ---- Flask Backend EC2 ----
resource "aws_instance" "flask_backend" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip python3-venv git
    cd /home/ubuntu
    git clone https://github.com/siddhipisal984/flask-express-deploy1.git
    cd flask-express-deploy1/flask-express-deploy/backend
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    nohup gunicorn --bind 0.0.0.0:5000 app:app > /var/log/flask.log 2>&1 &
  EOF

  tags = { Name = "flask-backend-ec2" }
}

# ---- Express Frontend EC2 ----
resource "aws_instance" "express_frontend" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs git
    cd /home/ubuntu
    git clone https://github.com/siddhipisal984/flask-express-deploy1.git
    cd flask-express-deploy1/flask-express-deploy/frontend
    npm install --production
    FLASK_URL=http://${aws_instance.flask_backend.private_ip}:5000 \
      nohup node server.js > /var/log/express.log 2>&1 &
  EOF

  tags = { Name = "express-frontend-ec2" }
}
