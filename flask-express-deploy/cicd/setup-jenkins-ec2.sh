#!/bin/bash
# =============================================================
# Setup Jenkins + Flask + Express on single EC2 (Ubuntu 22.04)
# Run this after SSH into your EC2 instance
# =============================================================

set -e

echo ">>> Updating system..."
sudo apt-get update -y

# ---- Install Java (Jenkins needs it) ----
echo ">>> Installing Java..."
sudo apt-get install -y openjdk-17-jdk

# ---- Install Jenkins ----
echo ">>> Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# ---- Install Python ----
echo ">>> Installing Python..."
sudo apt-get install -y python3 python3-pip python3-venv

# ---- Install Node.js ----
echo ">>> Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# ---- Install PM2 ----
echo ">>> Installing PM2..."
sudo npm install -g pm2

# ---- Install Git ----
sudo apt-get install -y git

# ---- Clone repo ----
echo ">>> Cloning repository..."
cd /home/ubuntu
git clone https://github.com/siddhipisal984/flask-express-deploy1.git
cd flask-express-deploy1/flask-express-deploy/backend

# ---- Setup Flask ----
echo ">>> Setting up Flask..."
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate

# ---- Start Flask with PM2 ----
echo ">>> Starting Flask with PM2..."
pm2 start "venv/bin/gunicorn --bind 0.0.0.0:5000 app:app" \
  --name flask-backend \
  --cwd /home/ubuntu/flask-express-deploy1/flask-express-deploy/backend

# ---- Setup Express ----
echo ">>> Setting up Express..."
cd /home/ubuntu/flask-express-deploy1/flask-express-deploy/frontend
npm install --production

# ---- Start Express with PM2 ----
echo ">>> Starting Express with PM2..."
FLASK_URL=http://localhost:5000 pm2 start server.js \
  --name express-frontend \
  --cwd /home/ubuntu/flask-express-deploy1/flask-express-deploy/frontend

pm2 save
pm2 startup

echo ""
echo "=== Setup Complete ==="
echo "Flask   : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5000"
echo "Express : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "Jenkins : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "Jenkins initial password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
