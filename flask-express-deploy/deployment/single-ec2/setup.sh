#!/bin/bash
# =============================================================
# Scenario 1: Deploy Flask + Express on a SINGLE EC2 instance
# Run this script on your EC2 instance (Ubuntu 22.04)
# =============================================================

set -e

echo ">>> Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# ---- Install Python & pip ----
echo ">>> Installing Python..."
sudo apt-get install -y python3 python3-pip python3-venv

# ---- Install Node.js ----
echo ">>> Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# ---- Install Nginx ----
echo ">>> Installing Nginx..."
sudo apt-get install -y nginx

# ---- Clone your repo (replace with your actual repo URL) ----
echo ">>> Cloning repository..."
cd /home/ubuntu
git clone https://github.com/siddhipisal984/flask-express-deploy1.git
cd flask-express-deploy1/flask-express-deploy

# ---- Setup Flask backend ----
echo ">>> Setting up Flask backend..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate
cd ..

# ---- Setup Express frontend ----
echo ">>> Setting up Express frontend..."
cd frontend
npm install --production
cd ..

# ---- Create systemd service for Flask ----
echo ">>> Creating Flask systemd service..."
sudo tee /etc/systemd/system/flask-backend.service > /dev/null <<EOF
[Unit]
Description=Flask Backend
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/flask-express-deploy1/flask-express-deploy/backend
Environment="PATH=/home/ubuntu/flask-express-deploy1/flask-express-deploy/backend/venv/bin"
ExecStart=/home/ubuntu/flask-express-deploy1/flask-express-deploy/backend/venv/bin/gunicorn --bind 127.0.0.1:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ---- Create systemd service for Express ----
echo ">>> Creating Express systemd service..."
sudo tee /etc/systemd/system/express-frontend.service > /dev/null <<EOF
[Unit]
Description=Express Frontend
After=network.target flask-backend.service

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/flask-express-deploy1/flask-express-deploy/frontend
Environment="PORT=3000"
Environment="FLASK_URL=http://127.0.0.1:5000"
ExecStart=/usr/bin/node server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ---- Configure Nginx as reverse proxy ----
echo ">>> Configuring Nginx..."
sudo tee /etc/nginx/sites-available/flask-express > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    # Express frontend (main entry)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    # Flask backend direct access (optional)
    location /flask/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/flask-express /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

# ---- Start all services ----
echo ">>> Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable flask-backend express-frontend nginx
sudo systemctl start flask-backend express-frontend nginx

echo ""
echo "=== Deployment Complete ==="
echo "Flask backend : http://localhost:5000"
echo "Express frontend: http://localhost:3000"
echo "Public URL      : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
